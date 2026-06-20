-- PeptiPrices.com supplier catalog + 5 new live scrapers (from peptiprices.com/suppliers)

insert into vendors (id, name, url, ships_from, notes, is_active) values
  ('e4000001-0000-4000-8000-00000000001f', 'Polaris Peptides', 'https://polarispeptides.com', 'USA', 'Scraper: live (Store API — PeptiPrices)', true),
  ('e4000001-0000-4000-8000-000000000020', 'Lumi Peptides', 'https://lumipeptides.com', 'USA', 'Scraper: live (Store API — PeptiPrices)', true),
  ('e4000001-0000-4000-8000-000000000021', 'Oneday Compounds', 'https://onedaycompounds.com', 'USA', 'Scraper: live (Store API — PeptiPrices)', true),
  ('e4000001-0000-4000-8000-000000000022', 'Alpha Peptides', 'https://alpha-peptides.com', 'USA', 'Scraper: live (Store API — PeptiPrices)', true),
  ('e4000001-0000-4000-8000-000000000023', 'Riptide Wellness', 'https://riptidewellness.com', 'USA', 'Scraper: live (Store API — PeptiPrices)', true),
  ('e4000001-0000-4000-8000-000000000024', 'Crownwell Research', 'https://crownwellresearch.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000025', 'NG Peptide', 'https://ngpeptide.com', 'USA', 'PeptiPrices — captcha blocked', false),
  ('e4000001-0000-4000-8000-000000000026', 'Sunrise Bioresearch', 'https://sunrisebioresearch.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000027', 'Felix Chem', 'https://felixchem.is', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000028', 'Science Based Peptides', 'https://sciencebasedpeptides.com', 'USA', 'PeptiPrices — login-gated API', false),
  ('e4000001-0000-4000-8000-000000000029', 'Flawless Compounds', 'https://flawlesscompounds.com', 'USA', 'PeptiPrices — login-gated API', false),
  ('e4000001-0000-4000-8000-00000000002a', 'Glow Aminos', 'https://glowaminos.com', 'USA', 'PeptiPrices — login-gated API', false),
  ('e4000001-0000-4000-8000-00000000002b', 'Southern Aminos', 'https://southernaminos.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-00000000002c', 'Puratek Peptides', 'https://puratekpeptides.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-00000000002d', 'Orbitrex Peptide', 'https://orbitrexpeptide.is', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-00000000002e', 'Modern Research', 'https://modernresearchpeptides.net', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-00000000002f', 'Simple Peptide', 'https://simplepeptide.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000030', 'Solution Peptides', 'https://solutionpeptides.net', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000031', 'True Peptide Labs', 'https://truepeptidelabs.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000032', 'Genetic Peptide', 'https://geneticpeptide.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000033', 'Blank Peptides', 'https://blankpeptides.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000034', 'Ascension Peptides', 'https://ascensionpeptides.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000035', 'My Oasis Labs', 'https://myoasislabs.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000036', 'Ion Peptide', 'https://ionpeptide.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000037', 'Paramount Peptides', 'https://paramountpeptides.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000038', 'Nextech Labs', 'https://nextechlaboratories.com', 'USA', 'PeptiPrices — scraper pending', false),
  ('e4000001-0000-4000-8000-000000000039', 'Bulk Peptides', 'https://bulkpeptides.com', 'USA', 'PeptiPrices — scraper pending', false)
on conflict (id) do update set
  name = excluded.name,
  url = excluded.url,
  notes = excluded.notes,
  is_active = excluded.is_active;

update peptides set aliases = array_cat(aliases, array['OC-3RT', 'OC-2TZ', 'LP1-SM', 'LP3-RT'])
where slug in ('retatrutide', 'tirzepatide', 'semaglutide')
  and not aliases @> array['OC-3RT'];
