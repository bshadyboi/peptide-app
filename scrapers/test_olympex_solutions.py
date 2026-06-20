"""Tests for Olympex simple product parser."""

import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.common.woocommerce import parse_simple_product

FIXTURE = """
<html><body>
<div class="product type-product instock">
  <p class="price"><span class="woocommerce-Price-amount amount"><bdi><span class="woocommerce-Price-currencySymbol">&#36;</span>39.99</bdi></span></p>
</div>
</body></html>
"""


def test_parse_simple_tb500():
    row = parse_simple_product("tb-500", FIXTURE, Decimal("5"))
    assert row is not None
    assert row.price == Decimal("39.99")
    assert row.in_stock is True


if __name__ == "__main__":
    test_parse_simple_tb500()
    print("ok")
