-- Search aliases for vendor-branded peptide names (Home search)

update peptides set aliases = array_cat(aliases, array['GLP-3 RT', 'GLP-3', 'GLP-3 RETA', 'Reta'])
where slug = 'retatrutide' and not aliases @> array['GLP-3 RT'];

update peptides set aliases = array_cat(aliases, array['GLP-1 S', 'GLP-1 SEMA', 'Sema'])
where slug = 'semaglutide' and not aliases @> array['GLP-1 SEMA'];

update peptides set aliases = array_cat(aliases, array['GLP-2 TZ', 'GLP-2 TIRZ', 'Tirz'])
where slug = 'tirzepatide' and not aliases @> array['GLP-2 TZ'];
