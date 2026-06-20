from __future__ import annotations

from decimal import Decimal

from scrapers.common.http import browser_session, fetch_html
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce import parse_variations_json
from scrapers.db import CORE_PEPTIDES_VENDOR_ID

DEFAULT_DISCOUNT_CODE = "CORE15"
BASE = "https://www.corepeptides.com/peptides"

PRODUCT_PAGES: list[dict[str, str]] = [
    {"peptide_slug": "bpc-157", "url": f"{BASE}/bpc-157/"},
    {"peptide_slug": "tb-500", "url": f"{BASE}/tb-500/"},
    {"peptide_slug": "ipamorelin", "url": f"{BASE}/ipamorelin/"},
    {"peptide_slug": "tesamorelin", "url": f"{BASE}/tesamorelin/"},
    {"peptide_slug": "ghrp-6", "url": f"{BASE}/ghrp-6/"},
    {"peptide_slug": "ghrp-2", "url": f"{BASE}/ghrp-2/"},
    {"peptide_slug": "aod-9604", "url": f"{BASE}/aod-9604-5mg/"},
    {"peptide_slug": "ghk-cu", "url": f"{BASE}/ghk-cu-50mg-copper/"},
    {"peptide_slug": "epitalon", "url": f"{BASE}/epitalon-25mg/"},
    {"peptide_slug": "mots-c", "url": f"{BASE}/mots-c-10mg/"},
    {"peptide_slug": "dsip", "url": f"{BASE}/dsip-5mg/"},
    {"peptide_slug": "cjc-1295-dac", "url": f"{BASE}/cjc-1295-dac-5mg/"},
    {"peptide_slug": "melanotan-ii", "url": f"{BASE}/melanotan-2-10mg/"},
    {"peptide_slug": "pt-141", "url": f"{BASE}/pt-141-10mg-bremelanotide/"},
    {"peptide_slug": "selank", "url": f"{BASE}/selank-10mg/"},
    {"peptide_slug": "semax", "url": f"{BASE}/semax-25mg/"},
    {"peptide_slug": "hexarelin", "url": f"{BASE}/hexarelin-5mg/"},
    {"peptide_slug": "bpc-tb-blend", "url": f"{BASE}/bpc-157-tb-500-10mg-blend/"},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCT_PAGES}


def scrape_core_peptides() -> list[ParsedVariation]:
    session = browser_session()
    all_variations: list[ParsedVariation] = []

    for product in PRODUCT_PAGES:
        page = fetch_html(product["url"], session)
        if not page:
            continue
        for row in parse_variations_json(product["peptide_slug"], page):
            row.product_url = product["url"]
            all_variations.append(row)

    return all_variations


def core_peptides_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations,
        dose_map,
        CORE_PEPTIDES_VENDOR_ID,
        EXPECTED_SLUGS,
        discount_code=DEFAULT_DISCOUNT_CODE,
    )
