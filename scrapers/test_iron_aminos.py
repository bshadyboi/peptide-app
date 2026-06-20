"""Tests for Iron Aminos single-vial variation parser."""

import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.vendors.iron_aminos import parse_single_vial_variation

FIXTURE = """
<html><body>
<form class="variations_form cart"
  data-product_variations='[
    {"attributes":{"attribute_vial-amount":"Single (1 Vial)"},"display_price":34.99,"display_regular_price":34.99,"is_in_stock":true},
    {"attributes":{"attribute_vial-amount":"10 Vials"},"display_price":259.99,"display_regular_price":259.99,"is_in_stock":true}
  ]'>
</form>
</body></html>
"""


def test_single_vial_only():
    row = parse_single_vial_variation("bpc-157", FIXTURE, Decimal("10"))
    assert row is not None
    assert row.mg == Decimal("10")
    assert row.price == Decimal("34.99")
    assert row.in_stock is True


if __name__ == "__main__":
    test_single_vial_only()
    print("ok")
