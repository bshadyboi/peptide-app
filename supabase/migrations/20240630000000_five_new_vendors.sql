-- Five new live scrapers: Pacific Edge, Vector Peps, Fusion Peptide, Hightide, Planet Peptides

insert into vendors (id, name, url, ships_from, notes, is_active) values
  ('e4000001-0000-4000-8000-00000000001e', 'Fusion Peptide', 'https://fusionpeptide.com', 'USA', 'Scraper: live (Store API)', true)
on conflict (id) do update set
  name = excluded.name,
  url = excluded.url,
  notes = excluded.notes,
  is_active = true;

update vendors set
  notes = 'Scraper: live (Store API — GLP-1/2/3)',
  is_active = true
where id in (
  'e4000001-0000-4000-8000-000000000005',  -- Vector Peps
  'e4000001-0000-4000-8000-00000000000e',  -- Hightide Compounds
  'e4000001-0000-4000-8000-00000000001a',  -- Pacific Edge Labs
  'e4000001-0000-4000-8000-00000000001d'   -- Planet Peptides
);

update peptides set aliases = array_cat(aliases, array['HTC-2 TZ', 'HTC-3 RT', 'HTC-31'])
where slug in ('tirzepatide', 'retatrutide', 'semaglutide')
  and not aliases @> array['HTC-2 TZ'];
