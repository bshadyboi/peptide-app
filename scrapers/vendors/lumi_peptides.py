from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import LUMI_PEPTIDES_VENDOR_ID

# From PeptiPrices supplier list — branded LP1-SM / LP2-TZ / LP3-RT
STORE_BASE = "https://lumipeptides.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-sm-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2-tz-30mg", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-rt-10mg-retatrutide-reta-retatrutide-10mg-reta10", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "variable": True, "mg": Decimal("100")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "semax", "store_slug": "semax-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb-500-blend", "variable": True, "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_lumi_peptides() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(1)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def lumi_peptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, LUMI_PEPTIDES_VENDOR_ID, EXPECTED_SLUGS
    )
