# Peptide Price Tracker — Build Spec

A price-comparison app for research peptides (singles + blends). Aggregates prices across vendors, sorts by price-per-mg, surfaces sales + discount codes, tracks price history, and sends alerts when a peptide drops below a target.

This is the source-of-truth spec. Build in the phase order at the bottom. Don't skip ahead — each phase ships something usable.

---

## Locked tech decisions

Don't substitute these unless I say so.

- **Backend / DB:** Supabase (Postgres + Auth + auto REST API + Edge Functions)
- **App:** SwiftUI + SwiftData (local cache), Swift Charts for history graphs
- **Scrapers + cron jobs:** Python (BeautifulSoup for static sites, Playwright for JS-heavy sites)
- **Job scheduling:** Supabase Edge Functions on cron (or a Railway worker if a job needs Playwright)
- **Push:** APNs (Apple Push Notification service) for price alerts

### Hard rules

1. **The iOS app NEVER scrapes.** It only reads clean JSON from the API and receives push. All scraping happens server-side. Apple rejects scraping apps and it would be slow.
2. **Always sort and compare by `price_per_mg`, not sticker price.** Dose sizes differ (5mg vs 10mg), so raw price is meaningless for comparison.
3. **Blends are multi-peptide.** A blend (e.g. a GH stack) maps to several component peptides with their own mg amounts. Use the junction table below — do NOT cram components into a text field.
4. **Alerts must run server-side on a schedule.** The app can't check prices while closed.

---

## Data model (Postgres / Supabase)

```sql
-- A peptide is either a single compound or a blend
create table peptides (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique not null,
  category    text not null check (category in ('single', 'blend')),
  aliases     text[] default '{}',        -- e.g. {'Body Protective Compound'}
  description text,
  created_at  timestamptz default now()
);

-- For blends: which singles make it up, and at what mg
create table blend_components (
  id                  uuid primary key default gen_random_uuid(),
  blend_id            uuid not null references peptides(id) on delete cascade,
  component_id        uuid not null references peptides(id),
  mg                  numeric not null
);

-- A specific purchasable size of a peptide (e.g. BPC-157 5mg)
create table doses (
  id          uuid primary key default gen_random_uuid(),
  peptide_id  uuid not null references peptides(id) on delete cascade,
  mg          numeric not null,
  label       text                       -- 'Kit', '10x vial', etc. (optional)
);

create table vendors (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  url         text,
  ships_from  text,
  notes       text
);

-- CURRENT price for a (dose, vendor) pair. One row per pair, upserted on each scrape.
create table prices (
  id             uuid primary key default gen_random_uuid(),
  dose_id        uuid not null references doses(id) on delete cascade,
  vendor_id      uuid not null references vendors(id) on delete cascade,
  price          numeric not null,
  sale_price     numeric,                                  -- null if not on sale
  -- effective price ÷ mg, generated automatically so it's always correct
  price_per_mg   numeric generated always as (
                   coalesce(sale_price, price) / nullif((select mg from doses d where d.id = dose_id), 0)
                 ) stored,
  currency       text default 'USD',
  in_stock       boolean default true,
  discount_code  text,
  coa_available  boolean default false,
  source         text not null check (source in ('scrape', 'manual', 'crowdsource')),
  last_seen_at   timestamptz default now(),
  created_at     timestamptz default now(),
  unique (dose_id, vendor_id)
);

-- Append-only daily log for the history chart
create table price_history (
  id            uuid primary key default gen_random_uuid(),
  dose_id       uuid not null references doses(id) on delete cascade,
  vendor_id     uuid not null references vendors(id) on delete cascade,
  price         numeric not null,
  price_per_mg  numeric,
  captured_at   timestamptz default now()
);

-- Auth users come from Supabase auth.users. Store their APNs token here.
create table user_devices (
  user_id     uuid references auth.users(id) on delete cascade,
  apns_token  text not null,
  updated_at  timestamptz default now(),
  primary key (user_id, apns_token)
);

-- A user's price alert on a specific dose
create table alerts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  dose_id         uuid not null references doses(id) on delete cascade,
  target_per_mg   numeric not null,        -- fire when best price_per_mg <= this
  active          boolean default true,
  last_fired_at   timestamptz,             -- debounce so it doesn't spam
  created_at      timestamptz default now()
);

-- Crowdsourced price/code submissions, reviewed before going live
create table price_submissions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id),
  dose_id        uuid references doses(id),
  vendor_name    text,                     -- free text; mapped to a vendor on approval
  price          numeric,
  discount_code  text,
  status         text default 'pending' check (status in ('pending','approved','rejected')),
  created_at     timestamptz default now()
);
```

Enable Row Level Security: `alerts`, `user_devices`, and `price_submissions` are per-user. `peptides`, `doses`, `vendors`, `prices`, `price_history` are public read.

---

## API surface

Supabase gives REST + filtering for free on the public tables. Use Edge Functions only where logic is needed (the three jobs + writes that need validation).

Read (public):
- `GET /peptides?category=single|blend` — list
- `GET /peptides/:slug` — peptide + its doses + current best price per dose
- `GET /doses/:id/prices` — all vendor prices for a dose, **ordered by `price_per_mg` asc**, out-of-stock last
- `GET /doses/:id/history?range=30d|90d|1y` — price_history points for the chart

Write (authed):
- `POST /alerts` — create/update an alert
- `DELETE /alerts/:id`
- `POST /submissions` — crowdsourced price/code
- `POST /devices` — register APNs token

---

## Background jobs (Edge Functions on cron)

1. **Scrape job** (per vendor, e.g. hourly or every few hours): fetch the vendor's catalog, parse price / in-stock / sale / code, then **upsert** into `prices` keyed on `(dose_id, vendor_id)`. Update `last_seen_at`. Mark `in_stock=false` if the listing is gone.
2. **Snapshot job** (daily, e.g. 3am): copy every current `prices` row into `price_history` with `captured_at = now()`. This is the entire history feature.
3. **Alert job** (e.g. hourly): for each active alert, find the current best `price_per_mg` for that dose. If it's `<= target_per_mg` and `last_fired_at` is older than ~24h, send an APNs push to the user's devices and set `last_fired_at = now()`.

Start scrapers as one vendor only (Phase 4). Don't build N scrapers up front.

---

## iOS app (SwiftUI + SwiftData)

### SwiftData models (local cache mirroring the API)
`Peptide`, `Dose`, `Vendor`, `Price`, `PricePoint` (history), `Alert`. Fetch from API → upsert into SwiftData → views read from SwiftData so the app works offline and feels instant.

### Screens
1. **Home / Search** — search bar, trending chips, two tabs: Singles / Blends. Tapping a result → detail.
2. **Peptide Detail (compare)** — dose selector (5mg / 10mg / Kit), best price pinned at top with `$/mg`, then the vendor list sorted by `price_per_mg`: vendor name, price (strikethrough original if on sale), `$/mg`, copyable discount code, in-stock status, COA flag. Out-of-stock greyed at the bottom. "Alert me" + "Price history" buttons.
3. **Price History** — Swift Charts line graph of `price_per_mg` over time per dose, range toggle (30d / 90d / 1y).
4. **Watchlist** — user's tracked doses with a red dot when current price is below their target.
5. **Submit** — simple form to submit a price + code for review (crowdsource).

### Networking + push
- Thin API client (URLSession + Codable). One decode layer; views never touch raw JSON.
- On launch + after login, register for remote notifications, send the APNs token to `POST /devices`.

---

## Build order (ship something each phase)

**Phase 1 — DB + manual data + compare UI.**
Create the schema. Seed ~5 peptides by hand (BPC-157, TB-500, Ipamorelin, Tesamorelin, one blend) with a few vendors and prices (`source='manual'`). Build the Peptide Detail compare screen against this real-but-manual data. Goal: the core screen looks right and sorts by `$/mg`.

**Phase 2 — API + app reads live.**
Wire the API client. Swap hardcoded data for live Supabase fetches into SwiftData. Build Home/Search.

**Phase 3 — History.**
Add the snapshot cron job. Build the Swift Charts history screen reading `price_history`. (Backfill a few fake-dated rows so the chart isn't empty during dev.)

**Phase 4 — First scraper.**
Pick the single cleanest vendor site. Write one Python scraper that upserts into `prices`. Get the full scrape→DB→API→app loop working end-to-end for that one vendor before adding more.

**Phase 5 — Crowdsource + alerts.**
Build the submit form + a basic approval flow (status field). Add the alert job + APNs push + the Watchlist screen and "Alert me" flow.

---

## Gotchas to not screw up
- `price_per_mg` is a generated column — never write it manually.
- Effective price = `coalesce(sale_price, price)`. Sorting/alerts use the effective price.
- Blends sort alongside singles fine because they have their own `doses` rows; `blend_components` is only for display ("what's in it").
- Alert debounce via `last_fired_at` or you'll spam the user every cron tick.
- RLS on per-user tables before going live, or anyone can read everyone's alerts.
