from __future__ import annotations

import time
from collections.abc import Callable
from decimal import Decimal

from scrapers.common.http import browser_session
from scrapers.common.sync import to_scraped_prices
from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce_store import scrape_store_catalog


def build_store_scraper(
    vendor_id: str,
    store_base: str,
    products: list[dict],
) -> tuple[Callable[[], list[ParsedVariation]], Callable[[list[ParsedVariation], dict], tuple]]:
    expected_slugs = {p["peptide_slug"] for p in products}

    def scrape() -> list[ParsedVariation]:
        session = browser_session()
        results: list[ParsedVariation] = []
        for index, product in enumerate(products):
            if index > 0:
                time.sleep(0.8)
            results.extend(scrape_store_catalog(session, store_base, [product]))
        return results

    def to_prices(
        variations: list[ParsedVariation],
        dose_map: dict[tuple[str, Decimal], str],
    ):
        return to_scraped_prices(variations, dose_map, vendor_id, expected_slugs)

    return scrape, to_prices


# Core catalog — most vendors stock these.
STANDARD_CATALOG: list[dict] = [
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157", "mg": Decimal("5")},
    {"peptide_slug": "bpc-157", "store_slug": "bpc-157-10mg", "mg": Decimal("10")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500", "mg": Decimal("5")},
    {"peptide_slug": "tb-500", "store_slug": "tb-500-10mg", "mg": Decimal("10")},
    {"peptide_slug": "semaglutide", "store_slug": "semaglutide", "mg": Decimal("5")},
    {"peptide_slug": "tirzepatide", "store_slug": "tirzepatide", "mg": Decimal("5")},
    {"peptide_slug": "retatrutide", "store_slug": "retatrutide", "mg": Decimal("5")},
    {"peptide_slug": "ipamorelin", "store_slug": "ipamorelin", "mg": Decimal("5")},
    {"peptide_slug": "tesamorelin", "store_slug": "tesamorelin", "mg": Decimal("5")},
    {"peptide_slug": "ghk-cu", "store_slug": "ghk-cu", "mg": Decimal("50")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "bpc-tb-blend", "mg": Decimal("10")},
]

# Extended catalog — tried per vendor; misses are ignored.
EXTENDED_CATALOG: list[dict] = STANDARD_CATALOG + [
    {"peptide_slug": "ghrp-6", "store_slug": "ghrp-6", "mg": Decimal("5")},
    {"peptide_slug": "ghrp-2", "store_slug": "ghrp-2", "mg": Decimal("5")},
    {"peptide_slug": "sermorelin", "store_slug": "sermorelin", "mg": Decimal("5")},
    {"peptide_slug": "hexarelin", "store_slug": "hexarelin", "mg": Decimal("5")},
    {"peptide_slug": "cagrilintide", "store_slug": "cagrilintide", "mg": Decimal("5")},
    {"peptide_slug": "survodutide", "store_slug": "survodutide", "mg": Decimal("5")},
    {"peptide_slug": "kpv", "store_slug": "kpv", "mg": Decimal("10")},
    {"peptide_slug": "ll-37", "store_slug": "ll-37", "mg": Decimal("5")},
    {"peptide_slug": "semax", "store_slug": "semax", "mg": Decimal("5")},
    {"peptide_slug": "selank", "store_slug": "selank", "mg": Decimal("5")},
    {"peptide_slug": "dsip", "store_slug": "dsip", "mg": Decimal("5")},
    {"peptide_slug": "adamax", "store_slug": "adamax", "mg": Decimal("5")},
    {"peptide_slug": "dihexa", "store_slug": "dihexa", "mg": Decimal("5")},
    {"peptide_slug": "epitalon", "store_slug": "epitalon", "mg": Decimal("10")},
    {"peptide_slug": "mots-c", "store_slug": "mots-c", "mg": Decimal("10")},
    {"peptide_slug": "ss-31", "store_slug": "ss-31", "mg": Decimal("10")},
    {"peptide_slug": "aod-9604", "store_slug": "aod-9604", "mg": Decimal("5")},
    {"peptide_slug": "5-amino-1mq", "store_slug": "5-amino-1mq", "mg": Decimal("50")},
    {"peptide_slug": "vip", "store_slug": "vip", "mg": Decimal("5")},
    {"peptide_slug": "ara-290", "store_slug": "ara-290", "mg": Decimal("10")},
    {"peptide_slug": "foxo4-dri", "store_slug": "foxo4-dri", "mg": Decimal("10")},
    {"peptide_slug": "ta-1", "store_slug": "thymosin-alpha-1", "mg": Decimal("5")},
    {"peptide_slug": "ta-1", "store_slug": "ta-1", "mg": Decimal("5")},
    {"peptide_slug": "igf-1-lr3", "store_slug": "igf-1-lr3", "mg": Decimal("1")},
    {"peptide_slug": "melanotan-ii", "store_slug": "melanotan-ii", "mg": Decimal("10")},
    {"peptide_slug": "melanotan-i", "store_slug": "melanotan-i", "mg": Decimal("10")},
    {"peptide_slug": "pt-141", "store_slug": "pt-141", "mg": Decimal("10")},
    {"peptide_slug": "snap-8", "store_slug": "snap-8", "mg": Decimal("10")},
    {"peptide_slug": "oxytocin", "store_slug": "oxytocin", "mg": Decimal("2")},
    {"peptide_slug": "kisspeptin", "store_slug": "kisspeptin", "mg": Decimal("5")},
    {"peptide_slug": "hgh-frag-176-191", "store_slug": "hgh-frag-176-191", "mg": Decimal("5")},
    {"peptide_slug": "peg-mgf", "store_slug": "peg-mgf", "mg": Decimal("2")},
    {"peptide_slug": "thymalin", "store_slug": "thymalin", "mg": Decimal("10")},
    {"peptide_slug": "nad-plus", "store_slug": "nad", "mg": Decimal("500")},
    {"peptide_slug": "nad-plus", "store_slug": "nad-plus", "mg": Decimal("500")},
    {"peptide_slug": "glutathione", "store_slug": "glutathione", "mg": Decimal("1500")},
    {"peptide_slug": "glow-blend", "store_slug": "glow-blend", "mg": Decimal("70")},
    {"peptide_slug": "klow-blend", "store_slug": "klow-blend", "mg": Decimal("80")},
    {"peptide_slug": "ghk-kpv-blend", "store_slug": "ghk-kpv-blend", "mg": Decimal("60")},
    {"peptide_slug": "cjc-ipa-blend", "store_slug": "cjc-ipa-blend", "mg": Decimal("10")},
    {"peptide_slug": "cjc-ipa-blend", "store_slug": "fit-stack-cjc-1295-ipamorelin", "mg": Decimal("10")},
    {"peptide_slug": "bpc-tb-blend", "store_slug": "wolverine-stack", "mg": Decimal("20")},
    {"peptide_slug": "glow-blend", "store_slug": "glow-advanced-peptide-blend-for-radiance-recovery", "mg": Decimal("70")},
    {"peptide_slug": "klow-blend", "store_slug": "klow-blend-bpc-157-tb-500-ghk-cu-kpv-10-10-50-10mg-blend", "mg": Decimal("80")},
    {"peptide_slug": "adamax", "store_slug": "adamax-vial", "mg": Decimal("5")},
    {"peptide_slug": "ghk-kpv-blend", "store_slug": "ghk-kpv-blend", "mg": Decimal("60")},
    {"peptide_slug": "epitalon", "store_slug": "epitalon-1mg", "mg": Decimal("1")},
    {"peptide_slug": "survodutide", "store_slug": "survodutide-vial", "mg": Decimal("5")},
]
