#!/usr/bin/env bash
# Deploy database migrations + edge functions to linked Supabase project.
# One-time auth (pick one):
#   npx supabase login
#   npx supabase login --token sbp_xxx   # from dashboard/account/tokens
#   export SUPABASE_ACCESS_TOKEN=sbp_xxx
#
# Usage:
#   ./scripts/deploy.sh
#   SUPABASE_PROJECT_REF=babwfemmozksdyklxhnu SUPABASE_DB_PASSWORD=xxx ./scripts/deploy.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Prefer global supabase; fall back to npm (works when Homebrew CLT is outdated)
if command -v supabase >/dev/null 2>&1; then
  SUPABASE=(supabase)
elif [[ -x "$ROOT/node_modules/.bin/supabase" ]]; then
  SUPABASE=("$ROOT/node_modules/.bin/supabase")
else
  echo "Installing Supabase CLI via npm (no Homebrew needed)..."
  npm install supabase --save-dev
  SUPABASE=("$ROOT/node_modules/.bin/supabase")
fi

run_supabase() {
  "${SUPABASE[@]}" "$@"
}

if [[ ! -d "$ROOT/supabase/migrations" ]]; then
  echo "Run from peptide-app repo root."
  exit 1
fi

# Auto-link if project ref + db password provided (CI / non-interactive)
if [[ -n "${SUPABASE_PROJECT_REF:-}" ]]; then
  if [[ ! -f "$ROOT/.supabase/config.toml" ]] || ! grep -q "project_id" "$ROOT/.supabase/config.toml" 2>/dev/null; then
    if [[ -z "${SUPABASE_DB_PASSWORD:-}" ]]; then
      echo "Set SUPABASE_DB_PASSWORD to link non-interactively, or run: supabase link --project-ref $SUPABASE_PROJECT_REF"
      exit 1
    fi
    run_supabase link --project-ref "$SUPABASE_PROJECT_REF" --password "$SUPABASE_DB_PASSWORD"
  fi
fi

echo "→ Pushing database migrations..."
run_supabase db push --yes

echo "→ Deploying edge functions..."
run_supabase functions deploy

if [[ -n "${ADMIN_SECRET:-}" ]]; then
  echo "→ Setting ADMIN_SECRET..."
  run_supabase secrets set "ADMIN_SECRET=$ADMIN_SECRET"
fi

echo ""
echo "Done. Database + functions are live."
echo ""
echo "One-time dashboard steps (not automatable):"
echo "  • Authentication → Providers → Anonymous → Enable"
echo "  • Edge Functions → Secrets → APNS_* (for push on iPhone)"
echo "  • GitHub repo secrets (see DEPLOY.md) for Actions scrapers"
