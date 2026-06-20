#!/usr/bin/env bash
# First-time local setup. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ Python scrapers venv..."
if [[ ! -d scrapers/.venv ]]; then
  python3 -m venv scrapers/.venv
fi
scrapers/.venv/bin/pip install -q -r scrapers/requirements.txt

if [[ ! -f scrapers/.env ]] && [[ -f scrapers/.env.example ]]; then
  cp scrapers/.env.example scrapers/.env
  echo "  Created scrapers/.env — add SUPABASE_URL + SERVICE_ROLE_KEY"
fi

if [[ ! -f Secrets.xcconfig ]] && [[ -f Secrets.xcconfig.example ]]; then
  cp Secrets.xcconfig.example Secrets.xcconfig
  echo "  Created Secrets.xcconfig — add anon key only"
fi

if command -v xcodegen >/dev/null 2>&1; then
  echo "→ Xcode project..."
  xcodegen generate
else
  echo "  Skip xcodegen (not installed). Run: brew install xcodegen"
fi

echo "→ Supabase CLI (npm — skips Homebrew)..."
npm install supabase --save-dev --silent 2>/dev/null || npm install supabase --save-dev

echo ""
echo "Local setup complete."
echo "Next:"
echo "  1. Fill scrapers/.env and Secrets.xcconfig"
echo "  2. npx supabase login && npx supabase link --project-ref YOUR_REF"
echo "  3. ./scripts/deploy.sh"
