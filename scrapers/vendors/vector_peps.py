from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import VECTOR_PEPS_VENDOR_ID

STORE_BASE = "https://vectorpeps.com"

# Branded GLP: GLP-1 SM, GLP-2 TZ, GLP-3 RT
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500", "mg": Decimal("10")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-10mg", "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-sm", "variable": True},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2-tz", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-rt", "variable": True},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "mg": Decimal("100")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c", "variable": True},
    {"peptide_slug": "epitalon", "store_slug": "epithalon-40mg", "mg": Decimal("25")},
    {"peptide_slug": "selank", "store_slug": "selank-10mg", "mg": Decimal("10")},
    {"peptide_slug": "semax", "store_slug": "semax-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tesamorelin", "store_slug": "tesamorelin-10mg", "mg": Decimal("10")},
    {"peptide_slug": "aod-9604", "store_slug": "aod-9604-5mg", "mg": Decimal("5")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb-500-blend", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_vector_peps() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def vector_peps_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, VECTOR_PEPS_VENDOR_ID, EXPECTED_SLUGS
    )
