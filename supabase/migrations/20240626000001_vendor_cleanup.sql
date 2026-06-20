-- Hide closed / stale vendors from the compare UI

alter table vendors add column if not exists is_active boolean not null default true;

update vendors
set is_active = false,
    notes = 'Closed — no longer selling.'
where id = 'e4000001-0000-4000-8000-000000000001';

update vendors
set is_active = false,
    notes = 'Inactive — stale manual seed; scraper blocked by Cloudflare.'
where id = 'e4000001-0000-4000-8000-000000000003';

-- Remove stale manual prices so they do not appear in compare
delete from prices
where vendor_id in (
  'e4000001-0000-4000-8000-000000000001',
  'e4000001-0000-4000-8000-000000000003'
)
and source = 'manual';
