-- Catalog expansion v2: 14 singles + 3 blends + vendor batch 2 activation

insert into peptides (id, name, slug, category, aliases, description) values
  ('a1000001-0000-4000-8000-000000000023', 'Thymosin Alpha-1', 'ta-1', 'single', array['TA1', 'Thymalin fragment'], 'Immune-modulating peptide.'),
  ('a1000001-0000-4000-8000-000000000024', 'IGF-1 LR3', 'igf-1-lr3', 'single', array['IGF1-LR3'], 'Long-acting insulin-like growth factor analog.'),
  ('a1000001-0000-4000-8000-000000000025', 'FOXO4-DRI', 'foxo4-dri', 'single', array['Proxofim'], 'Senolytic peptide studied in aging research.'),
  ('a1000001-0000-4000-8000-000000000026', 'Dihexa', 'dihexa', 'single', array['PNB-0408'], 'Cognitive research peptide / HGF mimetic.'),
  ('a1000001-0000-4000-8000-000000000027', 'Snap-8', 'snap-8', 'single', array['Acetyl Octapeptide-3'], 'Cosmetic peptide for expression lines.'),
  ('a1000001-0000-4000-8000-000000000028', 'VIP', 'vip', 'single', array['Vasoactive Intestinal Peptide'], 'Neuropeptide studied for inflammation and gut research.'),
  ('a1000001-0000-4000-8000-000000000029', 'Oxytocin', 'oxytocin', 'single', '{}', 'Neuropeptide hormone.'),
  ('a1000001-0000-4000-8000-00000000002a', 'Kisspeptin', 'kisspeptin', 'single', array['KP-10'], 'Reproductive axis signaling peptide.'),
  ('a1000001-0000-4000-8000-00000000002b', 'HGH Fragment 176-191', 'hgh-frag-176-191', 'single', array['AOD fragment', 'Frag 176-191'], 'HGH lipolytic fragment peptide.'),
  ('a1000001-0000-4000-8000-00000000002c', 'PEG-MGF', 'peg-mgf', 'single', array['Pegylated MGF'], 'Mechano growth factor variant.'),
  ('a1000001-0000-4000-8000-00000000002d', 'Adamax', 'adamax', 'single', array['Semax variant'], 'Semax-derived nootropic peptide.'),
  ('a1000001-0000-4000-8000-00000000002e', 'ARA-290', 'ara-290', 'single', array['Cibinetide'], 'Erythropoietin-derived tissue protective peptide.'),
  ('a1000001-0000-4000-8000-00000000002f', 'Thymalin', 'thymalin', 'single', array['Thymus peptide'], 'Thymus-derived peptide complex.'),
  ('a1000001-0000-4000-8000-000000000030', 'Survodutide', 'survodutide', 'single', array['GLP-1/glucagon'], 'Dual GLP-1 / glucagon agonist peptide.'),
  ('a1000001-0000-4000-8000-000000000031', 'GHK / KPV Blend', 'ghk-kpv-blend', 'blend', array['GHK-KPV'], 'GHK-Cu + KPV healing blend.'),
  ('a1000001-0000-4000-8000-000000000032', 'Tesamorelin / Ipamorelin Blend', 'tes-ipa-blend', 'blend', array['GH stack'], 'Tesamorelin + Ipamorelin growth stack.'),
  ('a1000001-0000-4000-8000-000000000033', 'GHRP-6 / Ipamorelin Blend', 'ghrp-ipa-blend', 'blend', array['GHRP/IPA'], 'GHRP-6 + Ipamorelin secretagogue stack.')
on conflict (slug) do update set
  name = excluded.name,
  category = excluded.category,
  aliases = excluded.aliases,
  description = excluded.description;

insert into blend_components (id, blend_id, component_id, mg) values
  ('b2000001-0000-4000-8000-00000000000c', 'a1000001-0000-4000-8000-000000000031', 'a1000001-0000-4000-8000-00000000000a', 50),
  ('b2000001-0000-4000-8000-00000000000d', 'a1000001-0000-4000-8000-000000000031', 'a1000001-0000-4000-8000-000000000019', 10),
  ('b2000001-0000-4000-8000-00000000000e', 'a1000001-0000-4000-8000-000000000032', 'a1000001-0000-4000-8000-000000000004', 5),
  ('b2000001-0000-4000-8000-00000000000f', 'a1000001-0000-4000-8000-000000000032', 'a1000001-0000-4000-8000-000000000003', 5),
  ('b2000001-0000-4000-8000-000000000010', 'a1000001-0000-4000-8000-000000000033', 'a1000001-0000-4000-8000-000000000007', 5),
  ('b2000001-0000-4000-8000-000000000011', 'a1000001-0000-4000-8000-000000000033', 'a1000001-0000-4000-8000-000000000003', 5)
on conflict (id) do nothing;

insert into doses (id, peptide_id, mg, label) values
  ('d3000001-0000-4000-8000-000000000043', 'a1000001-0000-4000-8000-000000000023', 5, null),
  ('d3000001-0000-4000-8000-000000000044', 'a1000001-0000-4000-8000-000000000023', 10, null),
  ('d3000001-0000-4000-8000-000000000045', 'a1000001-0000-4000-8000-000000000024', 1, null),
  ('d3000001-0000-4000-8000-000000000046', 'a1000001-0000-4000-8000-000000000025', 10, null),
  ('d3000001-0000-4000-8000-000000000047', 'a1000001-0000-4000-8000-000000000026', 5, null),
  ('d3000001-0000-4000-8000-000000000048', 'a1000001-0000-4000-8000-000000000026', 10, null),
  ('d3000001-0000-4000-8000-000000000049', 'a1000001-0000-4000-8000-000000000027', 10, null),
  ('d3000001-0000-4000-8000-00000000004a', 'a1000001-0000-4000-8000-000000000028', 5, null),
  ('d3000001-0000-4000-8000-00000000004b', 'a1000001-0000-4000-8000-000000000028', 10, null),
  ('d3000001-0000-4000-8000-00000000004c', 'a1000001-0000-4000-8000-000000000029', 2, null),
  ('d3000001-0000-4000-8000-00000000004d', 'a1000001-0000-4000-8000-000000000029', 5, null),
  ('d3000001-0000-4000-8000-00000000004e', 'a1000001-0000-4000-8000-00000000002a', 5, null),
  ('d3000001-0000-4000-8000-00000000004f', 'a1000001-0000-4000-8000-00000000002a', 10, null),
  ('d3000001-0000-4000-8000-000000000050', 'a1000001-0000-4000-8000-00000000002b', 5, null),
  ('d3000001-0000-4000-8000-000000000051', 'a1000001-0000-4000-8000-00000000002c', 2, null),
  ('d3000001-0000-4000-8000-000000000052', 'a1000001-0000-4000-8000-00000000002d', 5, null),
  ('d3000001-0000-4000-8000-000000000053', 'a1000001-0000-4000-8000-00000000002e', 10, null),
  ('d3000001-0000-4000-8000-000000000054', 'a1000001-0000-4000-8000-00000000002f', 10, null),
  ('d3000001-0000-4000-8000-000000000055', 'a1000001-0000-4000-8000-000000000030', 5, null),
  ('d3000001-0000-4000-8000-000000000056', 'a1000001-0000-4000-8000-000000000030', 10, null),
  ('d3000001-0000-4000-8000-000000000057', 'a1000001-0000-4000-8000-000000000031', 60, '50/10mg'),
  ('d3000001-0000-4000-8000-000000000058', 'a1000001-0000-4000-8000-000000000032', 10, '5/5mg'),
  ('d3000001-0000-4000-8000-000000000059', 'a1000001-0000-4000-8000-000000000033', 10, '5/5mg'),
  -- Extra doses for high-traffic peptides
  ('d3000001-0000-4000-8000-00000000005a', 'a1000001-0000-4000-8000-00000000000e', 15, null),
  ('d3000001-0000-4000-8000-00000000005b', 'a1000001-0000-4000-8000-00000000000f', 15, null),
  ('d3000001-0000-4000-8000-00000000005c', 'a1000001-0000-4000-8000-00000000000f', 20, null),
  ('d3000001-0000-4000-8000-00000000005d', 'a1000001-0000-4000-8000-000000000005', 20, '10/10mg'),
  ('d3000001-0000-4000-8000-00000000005e', 'a1000001-0000-4000-8000-00000000001b', 1000, null)
on conflict (id) do nothing;

-- Vendor batch 2 (Store API verified)
insert into vendors (id, name, url, ships_from, notes, is_active) values
  ('e4000001-0000-4000-8000-00000000002c', 'Puratek Peptides', 'https://puratekpeptides.com', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-00000000002e', 'Modern Research', 'https://modernresearchpeptides.net', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-000000000031', 'True Peptide Labs', 'https://truepeptidelabs.com', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-000000000034', 'Ascension Peptides', 'https://ascensionpeptides.com', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-000000000035', 'My Oasis Labs', 'https://myoasislabs.com', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-000000000036', 'Ion Peptide', 'https://ionpeptide.com', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-000000000037', 'Paramount Peptides', 'https://paramountpeptides.com', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-000000000038', 'Nextech Labs', 'https://nextechlaboratories.com', 'USA', 'Scraper: live (Store API)', true),
  ('e4000001-0000-4000-8000-000000000039', 'Bulk Peptides', 'https://bulkpeptides.com', 'USA', 'Scraper: live (Store API)', true)
on conflict (id) do update set
  name = excluded.name,
  url = excluded.url,
  notes = excluded.notes,
  is_active = excluded.is_active;

-- Search aliases for new peptides + branded names
update peptides set aliases = array_cat(aliases, array['TA-1', 'Thymosin Alpha 1'])
where slug = 'ta-1' and not aliases @> array['TA-1'];

update peptides set aliases = array_cat(aliases, array['IGF1 LR3', 'Long R3 IGF-1'])
where slug = 'igf-1-lr3' and not aliases @> array['IGF1 LR3'];

update peptides set aliases = array_cat(aliases, array['Survodutide', 'BI 456906'])
where slug = 'survodutide' and not aliases @> array['Survodutide'];

update peptides set aliases = array_cat(aliases, array['FIT Stack', 'CJC IPA'])
where slug = 'cjc-ipa-blend' and not aliases @> array['FIT Stack'];
