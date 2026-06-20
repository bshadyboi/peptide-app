-- Phase 1 seed data: ~5 peptides, vendors, doses, manual prices
-- Run after migrations. price_per_mg is generated — never insert it.

-- ---------------------------------------------------------------------------
-- Peptides
-- ---------------------------------------------------------------------------

insert into peptides (id, name, slug, category, aliases, description) values
  (
    'a1000001-0000-4000-8000-000000000001',
    'BPC-157',
    'bpc-157',
    'single',
    array['Body Protective Compound'],
    'Pentadecapeptide studied for tissue repair and gut health.'
  ),
  (
    'a1000001-0000-4000-8000-000000000002',
    'TB-500',
    'tb-500',
    'single',
    array['Thymosin Beta-4'],
    'Synthetic fragment of thymosin beta-4.'
  ),
  (
    'a1000001-0000-4000-8000-000000000003',
    'Ipamorelin',
    'ipamorelin',
    'single',
    '{}',
    'Growth hormone secretagogue peptide.'
  ),
  (
    'a1000001-0000-4000-8000-000000000004',
    'Tesamorelin',
    'tesamorelin',
    'single',
    array['Egrifta'],
    'GHRH analog peptide.'
  ),
  (
    'a1000001-0000-4000-8000-000000000005',
    'CJC-1295 / Ipamorelin Blend',
    'cjc-ipa-blend',
    'blend',
    array['GH Stack'],
    'Blend of CJC-1295 (no DAC) and Ipamorelin.'
  );

-- Blend components: CJC-1295 (standalone row not needed for compare) + Ipamorelin
insert into peptides (id, name, slug, category, aliases, description) values
  (
    'a1000001-0000-4000-8000-000000000006',
    'CJC-1295 (no DAC)',
    'cjc-1295-no-dac',
    'single',
    '{}',
  null
  );

insert into blend_components (id, blend_id, component_id, mg) values
  ('b2000001-0000-4000-8000-000000000001', 'a1000001-0000-4000-8000-000000000005', 'a1000001-0000-4000-8000-000000000006', 2),
  ('b2000001-0000-4000-8000-000000000002', 'a1000001-0000-4000-8000-000000000005', 'a1000001-0000-4000-8000-000000000003', 2);

-- ---------------------------------------------------------------------------
-- Doses
-- ---------------------------------------------------------------------------

insert into doses (id, peptide_id, mg, label) values
  -- BPC-157
  ('d3000001-0000-4000-8000-000000000001', 'a1000001-0000-4000-8000-000000000001', 5, null),
  ('d3000001-0000-4000-8000-000000000002', 'a1000001-0000-4000-8000-000000000001', 10, null),
  -- TB-500
  ('d3000001-0000-4000-8000-000000000003', 'a1000001-0000-4000-8000-000000000002', 5, null),
  ('d3000001-0000-4000-8000-000000000004', 'a1000001-0000-4000-8000-000000000002', 10, 'Kit'),
  -- Ipamorelin
  ('d3000001-0000-4000-8000-000000000005', 'a1000001-0000-4000-8000-000000000003', 5, null),
  ('d3000001-0000-4000-8000-000000000006', 'a1000001-0000-4000-8000-000000000003', 10, null),
  -- Tesamorelin
  ('d3000001-0000-4000-8000-000000000007', 'a1000001-0000-4000-8000-000000000004', 2, null),
  ('d3000001-0000-4000-8000-000000000008', 'a1000001-0000-4000-8000-000000000004', 5, null),
  -- Blend
  ('d3000001-0000-4000-8000-000000000009', 'a1000001-0000-4000-8000-000000000005', 4, '2mg/2mg vial'),
  ('d3000001-0000-4000-8000-000000000010', 'a1000001-0000-4000-8000-000000000005', 10, '5mg/5mg vial');

-- ---------------------------------------------------------------------------
-- Vendors
-- ---------------------------------------------------------------------------

insert into vendors (id, name, url, ships_from, notes) values
  ('e4000001-0000-4000-8000-000000000001', 'Peptide Sciences', 'https://www.peptidesciences.com', 'USA', 'COA on most products'),
  ('e4000001-0000-4000-8000-000000000002', 'Core Peptides', 'https://corepeptides.com', 'USA', null),
  ('e4000001-0000-4000-8000-000000000003', 'Paradigm Peptides', 'https://paradigmpeptides.com', 'USA', 'Frequent sales'),
  ('e4000001-0000-4000-8000-000000000004', 'Swiss Chems', 'https://swisschems.is', 'USA', null);

-- ---------------------------------------------------------------------------
-- Prices (source = manual). price_per_mg is generated automatically.
-- ---------------------------------------------------------------------------

-- BPC-157 5mg
insert into prices (id, dose_id, vendor_id, price, sale_price, in_stock, discount_code, coa_available, source) values
  ('c5000001-0000-4000-8000-000000000001', 'd3000001-0000-4000-8000-000000000001', 'e4000001-0000-4000-8000-000000000001', 59.50, null, true, 'RESEARCH10', true, 'manual'),
  ('c5000001-0000-4000-8000-000000000002', 'd3000001-0000-4000-8000-000000000001', 'e4000001-0000-4000-8000-000000000002', 45.00, 38.25, true, 'CORE15', false, 'manual'),
  ('c5000001-0000-4000-8000-000000000003', 'd3000001-0000-4000-8000-000000000001', 'e4000001-0000-4000-8000-000000000003', 52.00, null, true, null, true, 'manual'),
  ('c5000001-0000-4000-8000-000000000004', 'd3000001-0000-4000-8000-000000000001', 'e4000001-0000-4000-8000-000000000004', 49.99, null, false, 'SWISS5', false, 'manual');

-- BPC-157 10mg
insert into prices (id, dose_id, vendor_id, price, sale_price, in_stock, discount_code, coa_available, source) values
  ('c5000001-0000-4000-8000-000000000005', 'd3000001-0000-4000-8000-000000000002', 'e4000001-0000-4000-8000-000000000001', 99.00, 89.10, true, 'RESEARCH10', true, 'manual'),
  ('c5000001-0000-4000-8000-000000000006', 'd3000001-0000-4000-8000-000000000002', 'e4000001-0000-4000-8000-000000000002', 79.00, null, true, null, false, 'manual'),
  ('c5000001-0000-4000-8000-000000000007', 'd3000001-0000-4000-8000-000000000002', 'e4000001-0000-4000-8000-000000000003', 85.00, null, true, 'PARA20', true, 'manual');

-- TB-500 5mg
insert into prices (id, dose_id, vendor_id, price, sale_price, in_stock, discount_code, coa_available, source) values
  ('c5000001-0000-4000-8000-000000000008', 'd3000001-0000-4000-8000-000000000003', 'e4000001-0000-4000-8000-000000000001', 55.00, null, true, null, true, 'manual'),
  ('c5000001-0000-4000-8000-000000000009', 'd3000001-0000-4000-8000-000000000003', 'e4000001-0000-4000-8000-000000000002', 42.00, null, true, 'CORE15', false, 'manual'),
  ('c5000001-0000-4000-8000-000000000010', 'd3000001-0000-4000-8000-000000000003', 'e4000001-0000-4000-8000-000000000004', 48.00, 40.80, false, null, false, 'manual');

-- Ipamorelin 5mg
insert into prices (id, dose_id, vendor_id, price, sale_price, in_stock, discount_code, coa_available, source) values
  ('c5000001-0000-4000-8000-000000000011', 'd3000001-0000-4000-8000-000000000005', 'e4000001-0000-4000-8000-000000000001', 38.00, null, true, 'RESEARCH10', true, 'manual'),
  ('c5000001-0000-4000-8000-000000000012', 'd3000001-0000-4000-8000-000000000005', 'e4000001-0000-4000-8000-000000000003', 35.00, 29.75, true, 'PARA20', true, 'manual'),
  ('c5000001-0000-4000-8000-000000000013', 'd3000001-0000-4000-8000-000000000005', 'e4000001-0000-4000-8000-000000000004', 32.00, null, true, null, false, 'manual');

-- Tesamorelin 2mg
insert into prices (id, dose_id, vendor_id, price, sale_price, in_stock, discount_code, coa_available, source) values
  ('c5000001-0000-4000-8000-000000000014', 'd3000001-0000-4000-8000-000000000007', 'e4000001-0000-4000-8000-000000000001', 75.00, null, true, null, true, 'manual'),
  ('c5000001-0000-4000-8000-000000000015', 'd3000001-0000-4000-8000-000000000007', 'e4000001-0000-4000-8000-000000000002', 68.00, 61.20, true, 'CORE15', false, 'manual');

-- CJC/Ipamorelin blend 4mg
insert into prices (id, dose_id, vendor_id, price, sale_price, in_stock, discount_code, coa_available, source) values
  ('c5000001-0000-4000-8000-000000000016', 'd3000001-0000-4000-8000-000000000009', 'e4000001-0000-4000-8000-000000000001', 52.00, null, true, 'RESEARCH10', true, 'manual'),
  ('c5000001-0000-4000-8000-000000000017', 'd3000001-0000-4000-8000-000000000009', 'e4000001-0000-4000-8000-000000000003', 44.00, 39.60, true, 'PARA20', true, 'manual'),
  ('c5000001-0000-4000-8000-000000000018', 'd3000001-0000-4000-8000-000000000009', 'e4000001-0000-4000-8000-000000000004', 46.00, null, false, 'SWISS5', false, 'manual');
