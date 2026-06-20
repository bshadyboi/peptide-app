from __future__ import annotations

import re
import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import IRON_AMINOS_VENDOR_ID

BASE_URL = "https://ironaminos.com"

# Branded GLP slugs: glp-1-sema, glp-2-tirz, glp-3-reta. Variable products use
# "Vial Amount" (single vs 10-pack); peptide strength comes from the product slug/name.
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-5mg", "variable": True, "mg": Decimal("5")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-sema-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-sema-20mg", "variable": True, "mg": Decimal("20")},
    {"peptide_slug": "semaglutide", "store_slug": "glp-1-sema-30mg", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2-tirz-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2-tirz", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "tirzepatide", "store_slug": "glp-2-tirz-60mg", "variable": True, "mg": Decimal("60")},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-reta-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-reta-20mg", "variable": True, "mg": Decimal("20")},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-reta", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-reta-50mg", "variable": True, "mg": Decimal("50")},
    {"peptide_slug": "retatrutide", "store_slug": "glp-3-reta-60mg", "variable": True, "mg": Decimal("60")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-50mg", "variable": True, "mg": Decimal("50")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu-100mg", "variable": True, "mg": Decimal("100")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "epitalon", "store_slug": "epithalon-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "melanotan-ii", "store_slug": "melanotan-2-mt-2-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "pt-141", "store_slug": "pt-141-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "selank", "store_slug": "selank-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "sermorelin", "store_slug": "sermorelin-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "aod-9604", "store_slug": "aod-9604-5mg", "variable": True, "mg": Decimal("5")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-10mg-tb-500-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "cjc-1295-dac", "store_slug": "cjc-1295-with-dac-5mg", "variable": True, "mg": Decimal("5")},
    {"peptide_slug": "cjc-ipa-blend", "store_slug": "cjc-1295-ipamorelin-10mg", "variable": True, "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_iron_aminos() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(2)
        results.extend(scrape_store_catalog(session, BASE_URL, [product]))
    return results


def iron_aminos_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations,
        dose_map,
        IRON_AMINOS_VENDOR_ID,
        EXPECTED_SLUGS,
    )
