from __future__ import annotations

import time
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog
from scrapers.db import PLANET_PEPTIDES_VENDOR_ID

STORE_BASE = "https://planetpeptide.com"

# Branded RUO names; skip bulk-* multi-vial listings
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-157-tb-500-10-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "semaglutide-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "tirz-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "tirzepatide", "store_slug": "tirzepatide-30mg", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "tirzepatide", "store_slug": "tirzepatide-ruo-60mg-coming-soon", "variable": True, "mg": Decimal("60")},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide-20mg", "variable": True, "mg": Decimal("20")},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide-ruo-30mg", "variable": True, "mg": Decimal("30")},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide-ruo-40mg", "variable": True, "mg": Decimal("40")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "variable": True, "mg": Decimal("100")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "epitalon", "store_slug": "epitalon-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin-10mg", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "pt-141", "store_slug": "pt-141", "variable": True, "mg": Decimal("10")},
    {"peptide_slug": "dsip", "store_slug": "dsip-5mg", "variable": True, "mg": Decimal("5")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_planet_peptides() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []
    for index, product in enumerate(PRODUCTS):
        if index > 0:
            time.sleep(2)
        results.extend(scrape_store_catalog(session, STORE_BASE, [product]))
    return results


def planet_peptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations, dose_map, PLANET_PEPTIDES_VENDOR_ID, EXPECTED_SLUGS
    )
