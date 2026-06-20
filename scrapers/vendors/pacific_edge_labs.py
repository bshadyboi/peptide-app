from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import PACIFIC_EDGE_LABS_VENDOR_ID

STORE_BASE = "https://www.pacificedgelabs.com"

# Branded GLP: GLP-1 SM, GLP-2 TRZ, GLP-3 RT
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-5mg", "mg": Decimal("5")},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-sm-15mg", "mg": Decimal("15")},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide-glp-3", "variable": True},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "variable": True},
    {"peptide_slug": "mots-c", "store_slug": "mots-c", "variable": True},
    {"peptide_slug": "epitalon", "store_slug": "epithalon-50mg", "mg": Decimal("25")},
    {"peptide_slug": "pt-141", "store_slug": "pt-141-10mg", "mg": Decimal("10")},
    {"peptide_slug": "dsip", "store_slug": "dsip-10mg", "mg": Decimal("10")},
    {"peptide_slug": "aod-9604", "store_slug": "aod-9604-5mg", "mg": Decimal("5")},
    {"peptide_slug": "selank", "store_slug": "selank", "variable": True},
    {"peptide_slug": "semax", "store_slug": "semax-5mg", "mg": Decimal("5")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "wolverine-stack-tb-500-10mg-bpc-157-10mg", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_pacific_edge_labs() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def pacific_edge_labs_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, PACIFIC_EDGE_LABS_VENDOR_ID, EXPECTED_SLUGS
    )
