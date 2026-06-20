from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import POLARIS_PEPTIDES_VENDOR_ID

# PeptiPrices top retatrutide supplier — polarispeptides.com
STORE_BASE = "https://polarispeptides.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "semaglutide-5mg", "mg": Decimal("5")},
    {"peptide_slug": "semaglutide", "store_slug": "semaglutide-10mg", "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide-5mg", "mg": Decimal("5")},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide-10mg-2", "mg": Decimal("10")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "mg": Decimal("100")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-10mg", "mg": Decimal("10")},
    {"peptide_slug": "pt-141", "store_slug": "pt-141-10mg", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb-500-blend", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_polaris_peptides() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def polaris_peptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, POLARIS_PEPTIDES_VENDOR_ID, EXPECTED_SLUGS
    )
