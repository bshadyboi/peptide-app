-- Mark live scrapers (safe to re-run)

update vendors set notes = 'Scraper: live (WooCommerce simple)' where id = 'e4000001-0000-4000-8000-000000000008';
update vendors set notes = 'Scraper: live (Store API)' where id = 'e4000001-0000-4000-8000-00000000000c';
update vendors set notes = 'Scraper: live (single-vial variations)' where id = 'e4000001-0000-4000-8000-000000000019';
update vendors set notes = 'Scraper: not scrapeable (no public prices)' where id = 'e4000001-0000-4000-8000-000000000015';
