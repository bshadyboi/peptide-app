from __future__ import annotations

from decimal import Decimal

from scrapers.common.types import ParsedVariation
from scrapers.db import ScrapedPrice


def to_scraped_prices(
    variations: list[ParsedVariation],
    dose_map: dict[tuple[str, Decimal], str],
    vendor_id: str,
    expected_peptide_slugs: set[str],
    *,
    discount_code: str | None = None,
    coa_available: bool = False,
) -> tuple[list[ScrapedPrice], list[str]]:
    scraped: list[ScrapedPrice] = []
    seen_dose_ids: set[str] = set()
    expected_dose_ids = {
        dose_map[key] for key in dose_map if key[0] in expected_peptide_slugs
    }

    for var in variations:
        key = (var.peptide_slug, var.mg)
        dose_id = dose_map.get(key)
        if not dose_id:
            continue
        seen_dose_ids.add(dose_id)
        scraped.append(
            ScrapedPrice(
                dose_id=dose_id,
                vendor_id=vendor_id,
                price=var.price,
                sale_price=var.sale_price,
                in_stock=var.in_stock,
                discount_code=discount_code,
                coa_available=coa_available,
                product_url=var.product_url,
            )
        )

    missing = [dose_id for dose_id in expected_dose_ids if dose_id not in seen_dose_ids]
    return scraped, missing
