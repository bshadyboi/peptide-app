"""Tests for Core Peptides parser using real variation JSON shape."""

import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.common.woocommerce import parse_variations_json

FIXTURE_HTML = """
<html><body>
<form class="variations_form cart"
  data-product_variations='[{"attributes":{"attribute_pa_size":"10mg"},"display_price":97,"display_regular_price":97,"is_in_stock":true,"wccs_is_on_sale":false},{"attributes":{"attribute_pa_size":"5mg"},"display_price":45,"display_regular_price":52,"is_in_stock":true,"wccs_is_on_sale":true}]'>
</form>
</body></html>
"""


def test_parse_bpc157_variations():
    rows = parse_variations_json("bpc-157", FIXTURE_HTML)
    assert len(rows) == 2

    five = next(r for r in rows if r.mg == Decimal("5"))
    assert five.price == Decimal("52")
    assert five.sale_price == Decimal("45")
    assert five.in_stock is True

    ten = next(r for r in rows if r.mg == Decimal("10"))
    assert ten.price == Decimal("97")
    assert ten.sale_price is None


if __name__ == "__main__":
    test_parse_bpc157_variations()
    print("ok")
