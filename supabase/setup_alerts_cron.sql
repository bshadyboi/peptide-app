-- Optional: hourly alert check via Edge Function (requires pg_cron + pg_net or manual cron).
-- Deploy check-alerts Edge Function, then schedule:
--   select cron.schedule('hourly-alert-check', '0 * * * *', $$ ... $$);

-- Manual test after deploy:
--   curl -X POST "https://YOUR_PROJECT.supabase.co/functions/v1/check-alerts" \
--     -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"

-- APNs secrets (Edge Function → Secrets):
--   APNS_KEY_ID, APNS_TEAM_ID, APNS_AUTH_KEY (.p8 contents), APNS_BUNDLE_ID
--   APNS_PRODUCTION=true for App Store builds

-- Enable anonymous sign-in in Supabase Dashboard → Authentication → Providers → Anonymous.
