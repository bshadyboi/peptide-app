-- Peptide Sciences voluntarily shut down — mark catalog unavailable (Phase 4)
update vendors
set notes = 'Closed — no longer selling. Prices marked out of stock.'
where id = 'e4000001-0000-4000-8000-000000000001';

update prices
set in_stock = false, last_seen_at = now()
where vendor_id = 'e4000001-0000-4000-8000-000000000001';
