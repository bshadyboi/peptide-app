#!/usr/bin/env python3
"""Run Core Peptides scraper only (legacy entry point)."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.db import get_client, load_dose_map, mark_out_of_stock, upsert_prices
from scrapers.vendors.core_peptides import core_peptides_to_prices, scrape_core_peptides


def main() -> int:
    client = get_client()
    dose_map = load_dose_map(client)
    variations = scrape_core_peptides()
    if not variations:
        print("No variations parsed.")
        return 1
    prices, missing = core_peptides_to_prices(variations, dose_map)
    written = upsert_prices(client, prices)
    from scrapers.db import CORE_PEPTIDES_VENDOR_ID

    mark_out_of_stock(client, CORE_PEPTIDES_VENDOR_ID, missing)
    print(f"Upserted {written} price row(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
