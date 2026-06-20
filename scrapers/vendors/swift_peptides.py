from __future__ import annotations

from decimal import Decimal

from scrapers.common.catalog_scrape import scrape_product_catalog
from scrapers.common.sync import to_scraped_prices
from scrapers.db import SWIFT_PEPTIDES_VENDOR_ID

PRODUCTS: list[dict] = [
    # Original catalog
    {"peptide_slug": "bpc-157", "url": "https://swiftpeptides.com/product/bpc-157/", "kind": "variable"},
    {"peptide_slug": "tb-500", "url": "https://swiftpeptides.com/product/tb-500/", "kind": "variable"},
    {
        "peptide_slug": "ipamorelin",
        "url": "https://swiftpeptides.com/product/ipamorelin/",
        "kind": "simple",
        "mg": Decimal("5"),
    },
    {"peptide_slug": "tesamorelin", "url": "https://swiftpeptides.com/product/tesamorelin/", "kind": "variable"},
    # Growth & healing
    {"peptide_slug": "ghrp-2", "url": "https://swiftpeptides.com/product/ghrp-2/", "kind": "variable"},
    {"peptide_slug": "sermorelin", "url": "https://swiftpeptides.com/product/sermorelin/", "kind": "variable"},
    {"peptide_slug": "hexarelin", "url": "https://swiftpeptides.com/product/hexarelin/", "kind": "variable"},
    {"peptide_slug": "aod-9604", "url": "https://swiftpeptides.com/product/aod-9604/", "kind": "variable"},
    {"peptide_slug": "dsip", "url": "https://swiftpeptides.com/product/dsip/", "kind": "variable"},
    {"peptide_slug": "epitalon", "url": "https://swiftpeptides.com/product/epitalon/", "kind": "simple", "mg": Decimal("10")},
    {"peptide_slug": "ghk-cu", "url": "https://swiftpeptides.com/product/ghk-cu/", "kind": "variable"},
    {"peptide_slug": "mots-c", "url": "https://swiftpeptides.com/product/mots-c/", "kind": "variable"},
    {"peptide_slug": "bpc-tb-blend", "url": "https://swiftpeptides.com/product/bpc157-tb500/", "kind": "variable"},
    # GLP stack (Swift labels GLP-1/2/3)
    {"peptide_slug": "semaglutide", "url": "https://swiftpeptides.com/product/glp-1/", "kind": "variable"},
    {"peptide_slug": "tirzepatide", "url": "https://swiftpeptides.com/product/glp-2/", "kind": "variable"},
    {"peptide_slug": "retatrutide", "url": "https://swiftpeptides.com/product/glp-3/", "kind": "variable"},
    # Cosmetic / cognitive
    {"peptide_slug": "melanotan-ii", "url": "https://swiftpeptides.com/product/melanotan-ii/", "kind": "variable"},
    {"peptide_slug": "pt-141", "url": "https://swiftpeptides.com/product/pt-141/", "kind": "variable"},
    {"peptide_slug": "selank", "url": "https://swiftpeptides.com/product/selank/", "kind": "variable"},
    {"peptide_slug": "semax", "url": "https://swiftpeptides.com/product/semax/", "kind": "variable"},
]

EXPECTED_SLUGS = {p["peptide_slug"] for p in PRODUCTS}


def scrape_swift_peptides():
    return scrape_product_catalog(PRODUCTS)


def swift_peptides_to_prices(variations, dose_map):
    return to_scraped_prices(
        variations, dose_map, SWIFT_PEPTIDES_VENDOR_ID, EXPECTED_SLUGS
    )
