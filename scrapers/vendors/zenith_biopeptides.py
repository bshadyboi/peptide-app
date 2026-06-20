from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import ZENITH_BIOPEPTIDES_VENDOR_ID

STORE_BASE = "https://zenithbiopeptides.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-10mg", "mg": Decimal("10")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-50mg", "mg": Decimal("50")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "mg": Decimal("100")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-2", "mg": Decimal("10")},
    {"peptide_slug": "selank", "store_slug": "selank10mg-2", "mg": Decimal("10")},
    {"peptide_slug": "semax", "store_slug": "semax", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb-500-blend", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_zenith_biopeptides() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def zenith_biopeptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, ZENITH_BIOPEPTIDES_VENDOR_ID, EXPECTED_SLUGS
    )
