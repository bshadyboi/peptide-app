from __future__ import annotations

from decimal import Decimal

from scrapers.common.http import browser_session, fetch_html
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce import parse_simple_product, parse_variations_json
from scrapers.db import SWISS_CHEMS_VENDOR_ID

DEFAULT_DISCOUNT_CODE = "SWISS5"

# Real markup from swisschems.is product pages (Phase 4)
PRODUCTS: list[dict] = [
    {
        "peptide_slug": "bpc-157",
        "url": "https://swisschems.is/product/bpc-157-with-arginine-salt/",
        "kind": "variable",
        "size_keys": ("attribute_bpc-157-5mg",),
    },
    {
        "peptide_slug": "tb-500",
        "url": "https://swisschems.is/product/tb-500-thymosin-beta-4-healing-bundle/",
        "kind": "simple",
        "mg": Decimal("5"),
    },
    {
        "peptide_slug": "tesamorelin",
        "url": "https://swisschems.is/product/tesamorelin-2mg-price-is-per-vial/",
        "kind": "variable",
        "size_keys": ("attribute_tesamorelin",),
        "mg_from_attribute": {"1 vial": Decimal("2")},
    },
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_swiss_chems() -> list[ParsedVariation]:
    session = browser_session()
    results: list[ParsedVariation] = []

    for product in PRODUCTS:
        page = fetch_html(product["url"], session)
        if not page:
            continue

        if product["kind"] == "simple":
            row = parse_simple_product(
                product["peptide_slug"], page, product["mg"]
            )
            if row:
                row.product_url = product["url"]
                results.append(row)
        else:
            for row in parse_variations_json(
                product["peptide_slug"],
                page,
                size_attribute_keys=product.get("size_keys", ()),
                mg_from_attribute=product.get("mg_from_attribute"),
            ):
                row.product_url = product["url"]
                results.append(row)

    return results


def swiss_chems_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations,
        dose_map,
        SWISS_CHEMS_VENDOR_ID,
        EXPECTED_SLUGS,
        discount_code=DEFAULT_DISCOUNT_CODE,
    )
