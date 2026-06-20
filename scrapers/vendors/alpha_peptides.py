from __future__ import annotations

import time

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import ALPHA_PEPTIDES_VENDOR_ID

# alpha-peptides.com (not Alpha Omega) — PeptiPrices supplier
STORE_BASE = "https://alpha-peptides.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157", "variable": True},
    {"peptide_slug": "tb-500", "store_slug": "tb-500", "variable": True},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-sm", "variable": True},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2-tz", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-rt", "variable": True},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "variable": True},
    {"peptide_slug": "mots-c", "store_slug": "mots-c", "variable": True},
    {"peptide_slug": "semax", "store_slug": "semax", "variable": True},
    {"peptide_slug": "selank", "store_slug": "selank", "variable": True},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_alpha_peptides() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def alpha_peptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, ALPHA_PEPTIDES_VENDOR_ID, EXPECTED_SLUGS
    )
