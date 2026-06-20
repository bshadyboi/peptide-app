from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import IRON_BIO_LAB_VENDOR_ID

# ironbiolab.com redirects → ironpeptide.com (Store API). Product pages on ironpeptides.is.
STORE_BASE = "https://ironpeptide.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-5mg", "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "sema-glp-1", "variable": True},
    {"peptide_slug": "tirzepatide", "store_slug": "t-glp-2", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3", "variable": True},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "variable": True},
    {"peptide_slug": "epitalon", "store_slug": "epitalon", "mg": Decimal("10")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-5mg", "mg": Decimal("10")},
    {"peptide_slug": "melanotan-ii", "store_slug": "melanotan-ii-mt-2-10mg", "mg": Decimal("10")},
    {"peptide_slug": "selank", "store_slug": "selank", "mg": Decimal("10")},
    {"peptide_slug": "aod-9604", "store_slug": "aod-9604-5mg", "mg": Decimal("5")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-tb", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_iron_bio_lab() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, _product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        batch = scrape_store_catalog(session, STORE_BASE, [_product])
        results.extend(batch)
    return results


def iron_bio_lab_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, IRON_BIO_LAB_VENDOR_ID, EXPECTED_SLUGS
    )
