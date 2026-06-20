from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal


@dataclass
class ParsedVariation:
    peptide_slug: str
    mg: Decimal
    price: Decimal
    sale_price: Decimal | None
    in_stock: bool
    product_url: str | None = None
