-- Iron Bio Lab: live Store API scraper (ironpeptide.com)
-- PetriTide: research-access gate — not scrapeable without credentials

update vendors
set url = 'https://ironpeptide.com',
    notes = 'Scraper: live (WooCommerce Store API; ironbiolab.com redirects here)'
where id = 'e4000001-0000-4000-8000-00000000000b';

update vendors
set notes = 'Scraper: gated (research-access login required)'
where id = 'e4000001-0000-4000-8000-000000000009';
