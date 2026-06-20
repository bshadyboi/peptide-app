from __future__ import annotations

from decimal import Decimal

from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce import parse_variations_json
from scrapers.db import PARADIGM_PEPTIDES_VENDOR_ID

DEFAULT_DISCOUNT_CODE = "PARA20"

# Search on paradigmpeptides.com (Cloudflare — requires Playwright, not requests)
SEARCH_BASE = "https://www.paradigmpeptides.com/?s={query}&post_type=product"

CATALOG: list[dict[str, str]] = [
    {"peptide_slug": "bpc-157", "query": "bpc-157"},
    {"peptide_slug": "tb-500", "query": "tb-500"},
    {"peptide_slug": "ipamorelin", "query": "ipamorelin"},
    {"peptide_slug": "tesamorelin", "query": "tesamorelin"},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in CATALOG}


def _find_product_url(page, query: str) -> str | None:
    search_url = SEARCH_BASE.format(query=query.replace(" ", "+"))
    page.goto(search_url, wait_until="domcontentloaded", timeout=60000)
    page.wait_for_timeout(2000)

    links = page.eval_on_selector_all(
        "a.woocommerce-LoopProduct-link, li.product a[href*='/product/']",
        "els => els.map(e => e.href)",
    )
    query_lower = query.lower()
    for href in links:
        if query_lower.replace("-", "") in href.lower().replace("-", ""):
            return href
    return links[0] if links else None


def scrape_paradigm_peptides() -> list[ParsedVariation]:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError as exc:
        raise RuntimeError(
            "Paradigm Peptides requires Playwright (Cloudflare). "
            "Run: pip install playwright && playwright install chromium"
        ) from exc

    results: list[ParsedVariation] = []

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            )
        )
        page = context.new_page()

        for item in CATALOG:
            product_url = _find_product_url(page, item["query"])
            if not product_url:
                continue
            page.goto(product_url, wait_until="domcontentloaded", timeout=60000)
            page.wait_for_timeout(1500)
            html = page.content()
            for row in parse_variations_json(item["peptide_slug"], html):
                row.product_url = product_url
                results.append(row)

        browser.close()

    return results


def paradigm_to_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
):
    return to_scraped_prices(
        variations,
        dose_map,
        PARADIGM_PEPTIDES_VENDOR_ID,
        EXPECTED_SLUGS,
        discount_code=DEFAULT_DISCOUNT_CODE,
        coa_available=True,
    )
