-- Dev backfill: ~30 days of price_history for BPC-157 5mg so the chart isn't empty.
-- Run after seed.sql. Safe to re-run only on a fresh DB (will duplicate if run twice).

insert into price_history (dose_id, vendor_id, price, price_per_mg, captured_at)
select
  p.dose_id,
  p.vendor_id,
  round((coalesce(p.sale_price, p.price) + (gs.n % 6) * 0.75)::numeric, 2),
  round((p.price_per_mg + (gs.n % 6) * 0.12)::numeric, 4),
  now() - (gs.n || ' days')::interval
from prices p
cross join generate_series(0, 29) as gs(n)
where p.dose_id = 'd3000001-0000-4000-8000-000000000001'
  and p.in_stock = true;

-- A few older points for 90d / 1y range testing (BPC-157 5mg, best vendor)
insert into price_history (dose_id, vendor_id, price, price_per_mg, captured_at) values
  ('d3000001-0000-4000-8000-000000000001', 'e4000001-0000-4000-8000-000000000002', 42.00, 8.40, now() - interval '60 days'),
  ('d3000001-0000-4000-8000-000000000001', 'e4000001-0000-4000-8000-000000000002', 44.00, 8.80, now() - interval '120 days'),
  ('d3000001-0000-4000-8000-000000000001', 'e4000001-0000-4000-8000-000000000002', 46.00, 9.20, now() - interval '300 days');
