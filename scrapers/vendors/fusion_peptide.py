from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import FUSION_PEPTIDE_VENDOR_ID

STORE_BASE = "https://fusionpeptide.com"

# Branded GLP: glp-1, glp-2, glp-3 (+ AM833 combo products skipped)
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157", "variable": True},
    {"peptide_slug": "tb-500", "store_slug": "tb-500", "variable": True},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1", "variable": True},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3", "variable": True},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "variable": True},
    {"peptide_slug": "ipamorelin", "store_slug": "cjc-1295-no-dac-ipamorelin", "variable": True},
    {"peptide_slug": "epitalon", "store_slug": "epithalon", "variable": True},
    {"peptide_slug": "dsip", "store_slug": "dsip", "variable": True},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb-500-blend", "variable": True},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_fusion_peptide() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def fusion_peptide_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, FUSION_PEPTIDE_VENDOR_ID, EXPECTED_SLUGS
    )
