import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5";

type AlertRow = {
  alert_id: string;
  user_id: string;
  dose_id: string;
  target_per_mg: number;
  best_price_per_mg: number;
  peptide_name: string;
  dose_mg: number;
};

type DeviceRow = {
  apns_token: string;
};

const APNS_HOST = Deno.env.get("APNS_PRODUCTION") === "true"
  ? "api.push.apple.com"
  : "api.sandbox.push.apple.com";

async function apnsJwt(): Promise<string | null> {
  const keyId = Deno.env.get("APNS_KEY_ID");
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const rawKey = Deno.env.get("APNS_AUTH_KEY");
  if (!keyId || !teamId || !rawKey) return null;

  const pem = rawKey.includes("BEGIN PRIVATE KEY")
    ? rawKey
    : `-----BEGIN PRIVATE KEY-----\n${rawKey}\n-----END PRIVATE KEY-----`;

  const key = await importPKCS8(pem, "ES256");
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuedAt()
    .setIssuer(teamId)
    .sign(key);
}

async function sendApns(
  token: string,
  title: string,
  body: string,
  bundleId: string,
  jwt: string,
): Promise<boolean> {
  const response = await fetch(`https://${APNS_HOST}/3/device/${token}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      aps: {
        alert: { title, body },
        sound: "default",
      },
    }),
  });
  return response.ok;
}

Deno.serve(async (req) => {
  if (req.method !== "POST" && req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  const { data: alerts, error } = await supabase.rpc("get_alerts_to_fire", {
    debounce_hours: 24,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const rows = (alerts ?? []) as AlertRow[];
  if (rows.length === 0) {
    return new Response(JSON.stringify({ checked: 0, notified: 0 }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  const bundleId = Deno.env.get("APNS_BUNDLE_ID") ?? "com.peptideprice.tracker";
  const jwt = await apnsJwt();
  const fired: string[] = [];
  let pushCount = 0;

  for (const row of rows) {
    const title = `${row.peptide_name} price alert`;
    const body =
      `Best price is $${Number(row.best_price_per_mg).toFixed(2)}/mg (target $${Number(row.target_per_mg).toFixed(2)}/mg)`;

    const { data: devices } = await supabase
      .from("user_devices")
      .select("apns_token")
      .eq("user_id", row.user_id) as { data: DeviceRow[] | null };

    if (jwt && devices?.length) {
      for (const device of devices) {
        const ok = await sendApns(device.apns_token, title, body, bundleId, jwt);
        if (ok) pushCount += 1;
      }
    }

    fired.push(row.alert_id);
  }

  if (fired.length > 0) {
    await supabase.rpc("mark_alerts_fired", { alert_ids: fired });
  }

  return new Response(
    JSON.stringify({
      checked: rows.length,
      notified: pushCount,
      apns_configured: jwt !== null,
      fired_alert_ids: fired,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
