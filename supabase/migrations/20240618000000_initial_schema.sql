-- Peptide Price Tracker — initial schema (Phase 1)

-- A peptide is either a single compound or a blend
create table peptides (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique not null,
  category    text not null check (category in ('single', 'blend')),
  aliases     text[] default '{}',
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
  label       text
);

create table vendors (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  url         text,
  ships_from  text,
  notes       text
);

-- CURRENT price for a (dose, vendor) pair. One row per pair, upserted on each scrape.
-- Postgres generated columns cannot use subqueries, so dose_mg is synced from doses
-- via trigger; price_per_mg keeps the same formula as the spec.
create table prices (
  id             uuid primary key default gen_random_uuid(),
  dose_id        uuid not null references doses(id) on delete cascade,
  vendor_id      uuid not null references vendors(id) on delete cascade,
  price          numeric not null,
  sale_price     numeric,
  dose_mg        numeric not null,
  price_per_mg   numeric generated always as (
                   coalesce(sale_price, price) / nullif(dose_mg, 0)
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

-- Keep dose_mg in sync with doses.mg (never write price_per_mg manually).
create or replace function prices_sync_dose_mg()
returns trigger
language plpgsql
as $$
begin
  select d.mg into strict new.dose_mg from doses d where d.id = new.dose_id;
  return new;
end;
$$;

create trigger prices_sync_dose_mg_trigger
  before insert or update on prices
  for each row
  execute function prices_sync_dose_mg();

create or replace function doses_propagate_mg_to_prices()
returns trigger
language plpgsql
as $$
begin
  if old.mg is distinct from new.mg then
    update prices set dose_mg = new.mg where dose_id = new.id;
  end if;
  return new;
end;
$$;

create trigger doses_propagate_mg_trigger
  after update of mg on doses
  for each row
  execute function doses_propagate_mg_to_prices();

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
  target_per_mg   numeric not null,
  active          boolean default true,
  last_fired_at   timestamptz,
  created_at      timestamptz default now()
);

-- Crowdsourced price/code submissions, reviewed before going live
create table price_submissions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id),
  dose_id        uuid references doses(id),
  vendor_name    text,
  price          numeric,
  discount_code  text,
  status         text default 'pending' check (status in ('pending','approved','rejected')),
  created_at     timestamptz default now()
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table peptides enable row level security;
alter table blend_components enable row level security;
alter table doses enable row level security;
alter table vendors enable row level security;
alter table prices enable row level security;
alter table price_history enable row level security;
alter table user_devices enable row level security;
alter table alerts enable row level security;
alter table price_submissions enable row level security;

-- Public read for catalog tables
create policy "peptides_public_read"
  on peptides for select
  using (true);

create policy "blend_components_public_read"
  on blend_components for select
  using (true);

create policy "doses_public_read"
  on doses for select
  using (true);

create policy "vendors_public_read"
  on vendors for select
  using (true);

create policy "prices_public_read"
  on prices for select
  using (true);

create policy "price_history_public_read"
  on price_history for select
  using (true);

-- Per-user tables
create policy "user_devices_select_own"
  on user_devices for select
  using (auth.uid() = user_id);

create policy "user_devices_insert_own"
  on user_devices for insert
  with check (auth.uid() = user_id);

create policy "user_devices_update_own"
  on user_devices for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "user_devices_delete_own"
  on user_devices for delete
  using (auth.uid() = user_id);

create policy "alerts_select_own"
  on alerts for select
  using (auth.uid() = user_id);

create policy "alerts_insert_own"
  on alerts for insert
  with check (auth.uid() = user_id);

create policy "alerts_update_own"
  on alerts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "alerts_delete_own"
  on alerts for delete
  using (auth.uid() = user_id);

create policy "price_submissions_select_own"
  on price_submissions for select
  using (auth.uid() = user_id);

create policy "price_submissions_insert_own"
  on price_submissions for insert
  with check (auth.uid() = user_id);

create policy "price_submissions_update_own"
  on price_submissions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "price_submissions_delete_own"
  on price_submissions for delete
  using (auth.uid() = user_id);
