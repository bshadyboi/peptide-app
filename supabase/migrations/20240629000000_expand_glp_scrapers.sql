-- Olympex + Eon scrapers expanded for GLP peptides (retatrutide, tirzepatide, etc.)

update vendors set notes = 'Scraper: live (WooCommerce; branded GLP slugs)' where id = 'e4000001-0000-4000-8000-000000000008';
update vendors set notes = 'Scraper: live (Store API; GLP-1/2/3 products)' where id = 'e4000001-0000-4000-8000-00000000000c';
