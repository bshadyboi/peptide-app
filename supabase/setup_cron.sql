-- Optional: schedule daily snapshot at 3am UTC (requires pg_cron extension enabled in Dashboard).
-- Skip if this errors — you can still run: select snapshot_prices();
-- Or deploy the snapshot-prices Edge Function with cron in config.toml.

create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule(
  'daily-price-snapshot',
  '0 3 * * *',
  $$ select public.snapshot_prices(); $$
);
