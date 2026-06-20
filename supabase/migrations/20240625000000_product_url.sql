-- Link each price row to the vendor's product page (set by scrapers).

alter table prices add column if not exists product_url text;
