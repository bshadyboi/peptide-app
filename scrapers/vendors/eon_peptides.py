from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import EON_PEPTIDES_VENDOR_ID

BASE_URL = "https://eonpeptides.com"

PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500", "mg": Decimal("5")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin", "mg": Decimal("5")},
    {"peptide_slug": "tesamorelin", "store_slug": "tesamorelin", "mg": Decimal("5")},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-s", "mg": Decimal("5")},
    {"peptide_slug": "tirzepatide", "store_slug": "tz-glp-2x", "variable": True},
    {"peptide_slug": "retatrutide", "store_slug": "rt-glp-3x-2", "variable": True},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "variable": True},
    {"peptide_slug": "mots-c", "store_slug": "mots-c", "mg": Decimal("10")},
    {"peptide_slug": "epitalon", "store_slug": "epithalon", "mg": Decimal("10")},
    {"peptide_slug": "selank", "store_slug": "selank", "mg": Decimal("5")},
    {"peptide_slug": "semax", "store_slug": "semax", "mg": Decimal("5")},
    {"peptide_slug": "pt-141", "store_slug": "pt-141", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb500", "mg": Decimal("10")},
    {"peptide_slug": "cjc-ipa-blend", "store_slug": "cjc-ipa-blend", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_eon_peptides() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(5)
        results.extend(scrape_store_catalog(session, BASE_URL, [product]))
    return results


def eon_peptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations,
        dose_map,
        EON_PEPTIDES_VENDOR_ID,
        EXPECTED_SLUGS,
    )
