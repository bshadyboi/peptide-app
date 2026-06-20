-- Safe cleanup: drops all app tables if they exist.
-- Run in Supabase SQL Editor before re-running the migration.

drop function if exists snapshot_prices();

drop table if exists price_submissions cascade;
drop table if exists alerts cascade;
drop table if exists user_devices cascade;
drop table if exists price_history cascade;
drop table if exists prices cascade;
drop table if exists vendors cascade;
drop table if exists doses cascade;
drop table if exists blend_components cascade;
drop table if exists peptides cascade;

drop function if exists doses_propagate_mg_to_prices();
drop function if exists prices_sync_dose_mg();
