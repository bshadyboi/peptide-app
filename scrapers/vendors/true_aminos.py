from __future__ import annotations

from decimal import Decimal

from scrapers.common.catalog_scrape import scrape_product_catalog
from scrapers.common.http import browser_session, fetch_html
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce import parse_variations_json
from scrapers.db import TRUE_AMINO_LABS_VENDOR_ID

BASE = "https://trueaminolabs.com/product"

# WooCommerce simple + variable products (True Amino Labs)
PRODUCTS: list[dict] = [
    {"peptide_slug": "bpc-157", "url": f"{BASE}/bpc157/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "bpc-157", "url": f"{BASE}/bpc157-10mg/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "url": f"{BASE}/tb500/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "tb-500", "url": f"{BASE}/tb500-10-mg/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "url": f"{BASE}/glp-r-10-mg/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "retatrutide", "url": f"{BASE}/glp-r-15mg/", "kind": "variable"},
    {"peptide_slug": "tirzepatide", "url": f"{BASE}/glp-t/", "kind": "variable"},
    {"peptide_slug": "tirzepatide", "url": f"{BASE}/glp-t-60-mg/", "kind": "simple", "mg": Decimal("30")},
    {"peptide_slug": "ghk-cu", "url": f"{BASE}/ghkcu-50mg/", "kind": "simple", "mg": Decimal("50")},
    {"peptide_slug": "epitalon", "url": f"{BASE}/epithalon-10-mg/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "epitalon", "url": f"{BASE}/epithalon-50-mg/", "kind": "simple", "mg": Decimal("25")},
    {"peptide_slug": "aod-9604", "url": f"{BASE}/aod9604-5-mg/", "kind": "simple", "mg": Decimal("5")},
    {"peptide_slug": "mots-c", "url": f"{BASE}/motsc-10mg/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "melanotan-ii", "url": f"{BASE}/melanotan-2/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "selank", "url": f"{BASE}/selank-10mg/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "url": f"{BASE}/bpc157-tb500-blend-10-mg/", "kind": "simple", "mg": Decimal("10")},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_true_aminos() -> list[ParsedVariation]:
    simple = [p for p in PRODUCTS if p.get("kind") != "variable"]
    variable = [p for p in PRODUCTS if p.get("kind") == "variable"]
    results = scrape_product_catalog(simple)

    session = browser_session()
    for product in variable:
        page = fetch_html(product["url"], session)
        if not page:
            continue
        for row in parse_variations_json(product["peptide_slug"], page):
            row.product_url = product["url"]
            results.append(row)

    return results


def true_aminos_to_prices(variations, dose_map):
    return to_scraped_prices(
        variations, dose_map, TRUE_AMINO_LABS_VENDOR_ID, EXPECTED_SLUGS
    )
