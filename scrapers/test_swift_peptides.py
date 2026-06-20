"""Tests for Swift Peptides parser."""

import sys
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.common.woocommerce import parse_simple_product, parse_variations_json

FIXTURES = Path(__file__).parent / "fixtures"


def test_swift_bpc157_variations():
    html = (FIXTURES / "swift-bpc157.html").read_text()
    rows = parse_variations_json("bpc-157", html)
    assert len(rows) >= 2
    five = next(r for r in rows if r.mg == Decimal("5"))
    assert five.price == Decimal("41.99")
    assert five.in_stock is True


def test_swift_ipamorelin_simple():
    html = (FIXTURES / "swift-ipamorelin.html").read_text()
    row = parse_simple_product("ipamorelin", html, Decimal("5"))
    assert row is not None
    assert row.price == Decimal("43.99")
    assert row.in_stock is True


if __name__ == "__main__":
    test_swift_bpc157_variations()
    test_swift_ipamorelin_simple()
    print("ok")
