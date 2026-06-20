from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import HIGHTIDE_COMPOUNDS_VENDOR_ID

STORE_BASE = "https://hightidecompounds.com"

# Branded GLP: HTC-2 TZ (tirz), HTC-3 RT (reta), HTC-31 (sema)
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "htc-31-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "htc-2-tz-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "htc-2-tz-20mg", "variable": True, "mg": Decimal("20")},
    {"peptide_slug": "tirzepatide", "store_slug": "htc-2-tz-30mg", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "tirzepatide", "store_slug": "htc-2-tz-60mg", "variable": True, "mg": Decimal("60")},
    {"peptide_slug": "retatrutide", "store_slug": "htc-3-rt-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "store_slug": "htc-3-rt-20mg", "variable": True, "mg": Decimal("20")},
    {"peptide_slug": "retatrutide", "store_slug": "htc-3-rt-30mg", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-50mg", "variable": True, "mg": Decimal("50")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "variable": True, "mg": Decimal("100")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "epitalon", "store_slug": "epitalon-50mg", "variable": True, "mg": Decimal("25")},
    {"peptide_slug": "selank", "store_slug": "selank-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "semax", "store_slug": "semax-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tesamorelin", "store_slug": "tesamorelin-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb500-10mg-10mg", "variable": True, "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_hightide_compounds() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def hightide_compounds_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, HIGHTIDE_COMPOUNDS_VENDOR_ID, EXPECTED_SLUGS
    )
