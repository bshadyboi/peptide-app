from __future__ import annotations

import time

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import PRIME_PEPTIDES_VENDOR_ID

STORE_BASE = "https://primepeptides.co"

PRODUCTS: list[dict] = [
    {"peptide_slug": "semaglutide", "store_slug": "semaglutide", "variable": True},
    {"peptide_slug": "tirzepatide", "store_slug": "tirz", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide", "variable": True},
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157", "variable": True},
    {"peptide_slug": "tb-500", "store_slug": "tb-500", "variable": True},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "variable": True},
    {"peptide_slug": "semax", "store_slug": "semax", "variable": True},
    {"peptide_slug": "selank", "store_slug": "selank", "variable": True},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_prime_peptides() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def prime_peptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, PRIME_PEPTIDES_VENDOR_ID, EXPECTED_SLUGS
    )
