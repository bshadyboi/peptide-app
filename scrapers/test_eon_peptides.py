"""Tests for WooCommerce Store API parser."""

import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.common.woocommerce_store import parse_store_product

SAMPLE = {
    "is_in_stock": True,
    "attributes": [
        {
            "name": "Strength",
            "terms": [{"slug": "5mg", "name": "5mg"}],
        }
    ],
    "prices": {
        "price": "8500",
        "regular_price": "8500",
        "sale_price": "8500",
        "currency_minor_unit": 2,
    },
}


def test_parse_store_product_tb500():
    row = parse_store_product("tb-500", SAMPLE, mg=Decimal("5"))
    assert row is not None
    assert row.mg == Decimal("5")
    assert row.price == Decimal("85")
    assert row.in_stock is True


if __name__ == "__main__":
    test_parse_store_product_tb500()
    print("ok")
