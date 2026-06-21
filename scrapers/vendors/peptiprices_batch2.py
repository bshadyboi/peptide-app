from __future__ import annotations

from decimal import Decimal

from scrapers.common.store_scraper_factory import EXTENDED_CATALOG, build_store_scraper
from scrapers.db import (
    ASCENSION_PEPTIDES_VENDOR_ID,
    BULK_PEPTIDES_VENDOR_ID,
    ION_PEPTIDE_VENDOR_ID,
    MODERN_RESEARCH_VENDOR_ID,
    MY_OASIS_LABS_VENDOR_ID,
    NEXTECH_LABS_VENDOR_ID,
    PARAMOUNT_PEPTIDES_VENDOR_ID,
    PURATEK_PEPTIDES_VENDOR_ID,
    TRUE_PEPTIDE_LABS_VENDOR_ID,
)

# Ascension uses branded slugs for GLP products.
ASCENSION_CATALOG: list[dict] = [
    {"peptide_slug": "retatrutide", "store_slug": "r-10", "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "store_slug": "r-30", "mg": Decimal("30")},
    {"peptide_slug": "tirzepatide", "store_slug": "t-10", "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "t-30", "mg": Decimal("30")},
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "wolverine-stack", "mg": Decimal("20")},
    {"peptide_slug": "glow-blend", "store_slug": "glow-advanced-peptide-blend-for-radiance-recovery", "mg": Decimal("70")},
    {"peptide_slug": "klow-blend", "store_slug": "klow-ghk-cu-bpc-157-thymosin-beta4-kpv", "mg": Decimal("80")},
    {"peptide_slug": "cjc-ipa-blend", "store_slug": "fit-stack-cjc-1295-ipamorelin", "mg": Decimal("10")},
    {"peptide_slug": "cjc-ipa-blend", "store_slug": "cjc-1295-no-dac-10mg-ipamorelin-10mg-20mg", "mg": Decimal("20")},
    {"peptide_slug": "foxo4-dri", "store_slug": "fox04-dri", "mg": Decimal("10")},
    {"peptide_slug": "ara-290", "store_slug": "ara-290-10mg", "mg": Decimal("10")},
    {"peptide_slug": "5-amino-1mq", "store_slug": "5-amino-1mq-10-mg", "mg": Decimal("10")},
    {"peptide_slug": "nad-plus", "store_slug": "nad-1000mg", "mg": Decimal("1000")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "mg": Decimal("100")},
]

scrape_puratek_peptides, puratek_peptides_to_prices = build_store_scraper(
    PURATEK_PEPTIDES_VENDOR_ID, "https://puratekpeptides.com", EXTENDED_CATALOG
)
scrape_modern_research, modern_research_to_prices = build_store_scraper(
    MODERN_RESEARCH_VENDOR_ID, "https://modernresearchpeptides.net", EXTENDED_CATALOG
)
scrape_true_peptide_labs, true_peptide_labs_to_prices = build_store_scraper(
    TRUE_PEPTIDE_LABS_VENDOR_ID, "https://truepeptidelabs.com", EXTENDED_CATALOG
)
scrape_ascension_peptides, ascension_peptides_to_prices = build_store_scraper(
    ASCENSION_PEPTIDES_VENDOR_ID, "https://ascensionpeptides.com", ASCENSION_CATALOG
)
scrape_my_oasis_labs, my_oasis_labs_to_prices = build_store_scraper(
    MY_OASIS_LABS_VENDOR_ID, "https://myoasislabs.com", EXTENDED_CATALOG
)
scrape_ion_peptide, ion_peptide_to_prices = build_store_scraper(
    ION_PEPTIDE_VENDOR_ID, "https://ionpeptide.com", EXTENDED_CATALOG
)
scrape_paramount_peptides, paramount_peptides_to_prices = build_store_scraper(
    PARAMOUNT_PEPTIDES_VENDOR_ID, "https://paramountpeptides.com", EXTENDED_CATALOG
)
scrape_nextech_labs, nextech_labs_to_prices = build_store_scraper(
    NEXTECH_LABS_VENDOR_ID, "https://nextechlaboratories.com", EXTENDED_CATALOG
)
scrape_bulk_peptides, bulk_peptides_to_prices = build_store_scraper(
    BULK_PEPTIDES_VENDOR_ID, "https://bulkpeptides.com", EXTENDED_CATALOG
)

PEPTIPRICES_BATCH2_SCRAPERS = [
    ("Puratek Peptides", scrape_puratek_peptides, puratek_peptides_to_prices),
    ("Modern Research", scrape_modern_research, modern_research_to_prices),
    ("True Peptide Labs", scrape_true_peptide_labs, true_peptide_labs_to_prices),
    ("Ascension Peptides", scrape_ascension_peptides, ascension_peptides_to_prices),
    ("My Oasis Labs", scrape_my_oasis_labs, my_oasis_labs_to_prices),
    ("Ion Peptide", scrape_ion_peptide, ion_peptide_to_prices),
    ("Paramount Peptides", scrape_paramount_peptides, paramount_peptides_to_prices),
    ("Nextech Labs", scrape_nextech_labs, nextech_labs_to_prices),
    ("Bulk Peptides", scrape_bulk_peptides, bulk_peptides_to_prices),
]
