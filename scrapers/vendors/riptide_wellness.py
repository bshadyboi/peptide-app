from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import RIPTIDE_WELLNESS_VENDOR_ID

STORE_BASE = "https://riptidewellness.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "semaglutide", "store_slug": "cag-glp1-s", "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "glp2-t-30mg", "mg": Decimal("30")},
    {"peptide_slug": "tirzepatide", "store_slug": "glp2-t", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "glp3-r-10mg", "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "store_slug": "glp3-r", "variable": True},
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "mg": Decimal("100")},
    {"peptide_slug": "semax", "store_slug": "semx", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_riptide_wellness() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def riptide_wellness_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, RIPTIDE_WELLNESS_VENDOR_ID, EXPECTED_SLUGS
    )
