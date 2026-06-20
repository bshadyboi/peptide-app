"""Tests for Swiss Chems parser using saved HTML fixtures."""

import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.vendors.swiss_chems import scrape_swiss_chems

FIXTURES = Path(__file__).parent / "fixtures"


def test_swiss_tb500_fixture():
    from scrapers.common.woocommerce import parse_simple_product

    html = (FIXTURES / "swiss-tb500.html").read_text()
    row = parse_simple_product("tb-500", html, Decimal("5"))
    assert row is not None
    assert row.price == Decimal("38.95")
    assert row.in_stock is True


def test_swiss_bpc_variable_fixture():
    from scrapers.common.woocommerce import parse_variations_json

    html = (FIXTURES / "swiss-bpc-arg.html").read_text()
    rows = parse_variations_json(
        "bpc-157",
        html,
        size_attribute_keys=("attribute_bpc-157-5mg",),
    )
    assert len(rows) == 2
    five = next(r for r in rows if r.mg == Decimal("5"))
    assert five.price == Decimal("49.99")
    assert five.sale_price == Decimal("39.99")


if __name__ == "__main__":
    test_swiss_tb500_fixture()
    test_swiss_bpc_variable_fixture()
    print("ok")
