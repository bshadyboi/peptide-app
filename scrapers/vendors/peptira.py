from __future__ import annotations

from decimal import Decimal

from scrapers.common.catalog_scrape import scrape_product_catalog
from scrapers.common.sync import to_scraped_prices
from scrapers.db import PEPTIRA_VENDOR_ID

BASE = "https://peptira.com/product"

# Peptira branded names: reta3 = GLP-3, tesamorelin-2, ghk-cu-6, etc.
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "url": f"{BASE}/bpc-157/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "tb-500", "url": f"{BASE}/tb-500/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "ipamorelin", "url": f"{BASE}/ipamorelin/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "tesamorelin", "url": f"{BASE}/tesamorelin/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "tesamorelin", "url": f"{BASE}/tesamorelin-2/", "kind": "simple", "mg": Decimal("2")},
    {"peptide_slug": "ghk-cu", "url": f"{BASE}/ghk-cu-6/", "kind": "simple", "mg": Decimal("50")},
    {"peptide_slug": "mots-c", "url": f"{BASE}/mots-c-2/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "url": f"{BASE}/reta3/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "retatrutide", "url": f"{BASE}/reta3-5/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "retatrutide", "url": f"{BASE}/reta3-9/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "url": f"{BASE}/tb-bp-blend-wolverine/", "kind": "simple", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_peptira():
    return scrape_product_catalog(PRODUCTS)


def peptira_to_prices(variations, dose_map):
    return to_scraped_prices(
        variations, dose_map, PEPTIRA_VENDOR_ID, EXPECTED_SLUGS
    )
