from __future__ import annotations

from decimal import Decimal

from scrapers.common.http import browser_session, fetch_html
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce import parse_simple_product, parse_variations_json


def scrape_product_catalog(products: list[dict]) -> list[ParsedVariation]:
    """Scrape a list of WooCommerce product pages. Each dict needs url, peptide_slug, kind."""
    session = browser_session()
    results: list[ParsedVariation] = []

    for product in products:
        page = fetch_html(product["url"], session)
        if not page:
            continue

        if product.get("kind") == "variable":
            for row in parse_variations_json(product["peptide_slug"], page):
                row.product_url = product["url"]
                results.append(row)
        else:
            row = parse_simple_product(
                product["peptide_slug"], page, product["mg"]
            )
            if row:
                row.product_url = product["url"]
                results.append(row)

    return results
