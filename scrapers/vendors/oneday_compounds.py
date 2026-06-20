from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import ONEDAY_COMPOUNDS_VENDOR_ID

# Branded OC-3RT / OC-2TZ from PeptiPrices
STORE_BASE = "https://onedaycompounds.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "tirzepatide", "store_slug": "tirzepatide-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "tirz-30mg", "mg": Decimal("30")},
    {"peptide_slug": "retatrutide", "store_slug": "glp3-r-10mg", "mg": Decimal("10")},
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "mg": Decimal("50")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-10mg", "mg": Decimal("10")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-10mg", "mg": Decimal("10")},
    {"peptide_slug": "semax", "store_slug": "semax", "mg": Decimal("10")},
    {"peptide_slug": "selank", "store_slug": "selank", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "tb-500-bpc-157-blend-10mg-will-ship-by-5-12", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_oneday_compounds() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def oneday_compounds_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, ONEDAY_COMPOUNDS_VENDOR_ID, EXPECTED_SLUGS
    )
