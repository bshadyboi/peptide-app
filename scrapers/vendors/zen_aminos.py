from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import ZEN_AMINOS_VENDOR_ID

# zenaminos.com redirects → zenaminos.is. Branded ZAP-1S / ZAP-2T / ZAP-3R.
STORE_BASE = "https://zenaminos.is"

PRODUCTS: list[dict] = [
    {"peptide_slug": "semaglutide", "store_slug": "zap-1-s-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "zap-2t", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "zap-3r-multiple", "variable": True},
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "variable": True, "mg": Decimal("100")},
    {"peptide_slug": "semax", "store_slug": "semax-2", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_zen_aminos() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def zen_aminos_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, ZEN_AMINOS_VENDOR_ID, EXPECTED_SLUGS
    )
