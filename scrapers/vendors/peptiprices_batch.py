from __future__ import annotations

from scrapers.common.store_scraper_factory import EXTENDED_CATALOG, build_store_scraper
from scrapers.db import (
    BLANK_PEPTIDES_VENDOR_ID,
    CROWNWELL_RESEARCH_VENDOR_ID,
    FELIX_CHEM_VENDOR_ID,
    GENETIC_PEPTIDE_VENDOR_ID,
    SIMPLE_PEPTIDE_VENDOR_ID,
    SOLUTION_PEPTIDES_VENDOR_ID,
    SOUTHERN_AMINOS_VENDOR_ID,
    SUNRISE_BIORESEARCH_VENDOR_ID,
)

scrape_crownwell_research, crownwell_research_to_prices = build_store_scraper(
    CROWNWELL_RESEARCH_VENDOR_ID,
    "https://crownwellresearch.com",
    EXTENDED_CATALOG,
)

scrape_sunrise_bioresearch, sunrise_bioresearch_to_prices = build_store_scraper(
    SUNRISE_BIORESEARCH_VENDOR_ID,
    "https://sunrisebioresearch.com",
    EXTENDED_CATALOG,
)

scrape_felix_chem, felix_chem_to_prices = build_store_scraper(
    FELIX_CHEM_VENDOR_ID,
    "https://felixchem.is",
    EXTENDED_CATALOG,
)

scrape_southern_aminos, southern_aminos_to_prices = build_store_scraper(
    SOUTHERN_AMINOS_VENDOR_ID,
    "https://southernaminos.com",
    EXTENDED_CATALOG,
)

scrape_simple_peptide, simple_peptide_to_prices = build_store_scraper(
    SIMPLE_PEPTIDE_VENDOR_ID,
    "https://simplepeptide.com",
    EXTENDED_CATALOG,
)

scrape_solution_peptides, solution_peptides_to_prices = build_store_scraper(
    SOLUTION_PEPTIDES_VENDOR_ID,
    "https://solutionpeptides.net",
    EXTENDED_CATALOG,
)

scrape_genetic_peptide, genetic_peptide_to_prices = build_store_scraper(
    GENETIC_PEPTIDE_VENDOR_ID,
    "https://geneticpeptide.com",
    EXTENDED_CATALOG,
)

scrape_blank_peptides, blank_peptides_to_prices = build_store_scraper(
    BLANK_PEPTIDES_VENDOR_ID,
    "https://blankpeptides.com",
    EXTENDED_CATALOG,
)

PEPTIPRICES_BATCH_SCRAPERS = [
    ("Crownwell Research", scrape_crownwell_research, crownwell_research_to_prices),
    ("Sunrise Bioresearch", scrape_sunrise_bioresearch, sunrise_bioresearch_to_prices),
    ("Felix Chem", scrape_felix_chem, felix_chem_to_prices),
    ("Southern Aminos", scrape_southern_aminos, southern_aminos_to_prices),
    ("Simple Peptide", scrape_simple_peptide, simple_peptide_to_prices),
    ("Solution Peptides", scrape_solution_peptides, solution_peptides_to_prices),
    ("Genetic Peptide", scrape_genetic_peptide, genetic_peptide_to_prices),
    ("Blank Peptides", scrape_blank_peptides, blank_peptides_to_prices),
]
