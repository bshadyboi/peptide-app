-- Prime Peptides (new) + Zen Aminos live on zenaminos.is

insert into vendors (id, name, url, ships_from, notes, is_active) values
  ('e4000001-0000-4000-8000-00000000003a', 'Prime Peptides', 'https://primepeptides.co', 'USA', 'Scraper: live (Store API)', true)
on conflict (id) do update set
  name = excluded.name,
  url = excluded.url,
  notes = excluded.notes,
  is_active = true;

update vendors set
  url = 'https://zenaminos.is',
  notes = 'Scraper: live (Store API — ZAP-1S/2T/3R)',
  is_active = true
where id = 'e4000001-0000-4000-8000-000000000012';
