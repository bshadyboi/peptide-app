from __future__ import annotations

from decimal import Decimal

from scrapers.common.catalog_scrape import scrape_product_catalog
from scrapers.common.sync import to_scraped_prices
from scrapers.db import OLYMPEX_SOLUTIONS_VENDOR_ID

BASE = "https://olympexsolutions.com/product"

# Olympex uses branded slugs (e.g. OLY-31 = GLP-3 RT / retatrutide, GLP-2 TZ = tirzepatide).
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "url": f"{BASE}/bpc-157/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "tb-500", "url": f"{BASE}/tb-500/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "ipamorelin", "url": f"{BASE}/ipamorelin/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "tesamorelin", "url": f"{BASE}/tesamorelin/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "retatrutide", "url": f"{BASE}/oly-31/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "tirzepatide", "url": f"{BASE}/glp-1-tz/", "kind": "variable"},
    {"peptide_slug": "sermorelin", "url": f"{BASE}/7910/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "pt-141", "url": f"{BASE}/pt-141/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "dsip", "url": f"{BASE}/dsip/", "kind": "simple", "mg": Decimal("5")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_olympex_solutions():
    return scrape_product_catalog(PRODUCTS)


def olympex_solutions_to_prices(variations, dose_map):
    return to_scraped_prices(
        variations, dose_map, OLYMPEX_SOLUTIONS_VENDOR_ID, EXPECTED_SLUGS
    )
