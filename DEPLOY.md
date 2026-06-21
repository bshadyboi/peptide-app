# Deploy guide

## You only do manual work ONCE

After the one-time setup below, **routine updates are automatic**:

| What | How |
|------|-----|
| New SQL migrations | Commit → push to `main` → GitHub deploys |
| Edge function changes | Commit → push to `main` → GitHub deploys |
| Scraper price updates | GitHub runs every 6 hours |
| History snapshots | GitHub runs daily 3am UTC |
| Alert checks | GitHub runs hourly |

You do **not** need to paste SQL into the Dashboard every time we add a migration.

---

## One-time setup (~10 minutes)

### 1. Local tools

```bash
cd ~/Desktop/peptide-app
chmod +x scripts/*.sh
./scripts/setup.sh
brew install supabase/tap/supabase   # if needed
```

### 2. Fill secrets (local files, never commit)

**`scrapers/.env`** — service role for scrapers + review CLI:

```
SUPABASE_URL=https://YOUR_REF.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

**`Secrets.xcconfig`** — anon key for iOS only:

```
SUPABASE_URL = https:/$()/YOUR_REF.supabase.co
SUPABASE_ANON_KEY = eyJ...
```

Get keys: Supabase Dashboard → **Settings → API**.

### 3. Link Supabase CLI (once per machine)

```bash
supabase login
supabase link --project-ref YOUR_REF
# Enter database password when prompted
```

### 4. First deploy

```bash
./scripts/deploy.sh
```

Or deploy manually anytime after link:

```bash
supabase db push
supabase functions deploy
```

### 5. GitHub Actions secrets (once per repo)

Repo → **Settings → Secrets and variables → Actions**:

| Secret | Where to get it |
|--------|-----------------|
| `SUPABASE_ACCESS_TOKEN` | [Account tokens](https://supabase.com/dashboard/account/tokens) |
| `SUPABASE_PROJECT_REF` | Project URL subdomain, e.g. `babwfemmozksdyklxhnu` |
| `SUPABASE_DB_PASSWORD` | Password you set when creating the project |
| `SUPABASE_URL` | `https://YOUR_REF.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Settings → API → service_role |
| `ADMIN_SECRET` | (optional) any long random string for submission review API |

Push to `main` — **Deploy Supabase** workflow runs automatically when `supabase/` changes.

### 6. Dashboard checkboxes (once, cannot be scripted)

- **Authentication → Providers → Anonymous** → Enable
- **Edge Functions → Secrets → APNS_*** (only when testing push on a real iPhone)

### 7. Fresh database only

If the project has **no data yet**, run in SQL Editor once:

- `supabase/seed.sql`
- `supabase/seed_history.sql` (optional chart backfill)

Linked deploys (`db push`) handle all files in `supabase/migrations/` — no need to run seed on every deploy.

---

## Day-to-day commands

```bash
# Deploy everything (after supabase link)
./scripts/deploy.sh

# Run scrapers now
scrapers/.venv/bin/python scrapers/run_all.py

# Review crowdsource submissions
scrapers/.venv/bin/python scrapers/review_submissions.py list
scrapers/.venv/bin/python scrapers/review_submissions.py approve <uuid>

# Regenerate Xcode project
xcodegen generate && open PeptidePriceTracker.xcodeproj
```

---

## What still needs you manually

| Item | Why |
|------|-----|
| Anonymous auth toggle | Supabase Dashboard only |
| Apple APNs keys | Apple Developer account |
| Xcode signing team | Your Apple ID — see [TESTFLIGHT.md](TESTFLIGHT.md) |
| `seed.sql` on brand-new DB | One-time sample data |

Everything else — migrations, functions, scrapers, cron — runs from git push or GitHub schedules.
