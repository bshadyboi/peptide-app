#!/usr/bin/env python3
"""Run all vendor scrapers and sync to Supabase."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.db import (
    PEPTIDE_SCIENCES_VENDOR_ID,
    get_client,
    load_dose_map,
    mark_out_of_stock,
    mark_vendor_out_of_stock,
    upsert_prices,
)
from scrapers.vendors.core_peptides import core_peptides_to_prices, scrape_core_peptides
from scrapers.vendors.eon_peptides import eon_peptides_to_prices, scrape_eon_peptides
from scrapers.vendors.iron_bio_lab import iron_bio_lab_to_prices, scrape_iron_bio_lab
from scrapers.vendors.iron_aminos import iron_aminos_to_prices, scrape_iron_aminos
from scrapers.vendors.olympex_solutions import (
    olympex_solutions_to_prices,
    scrape_olympex_solutions,
)
from scrapers.vendors.peptira import peptira_to_prices, scrape_peptira
from scrapers.vendors.swiss_chems import scrape_swiss_chems, swiss_chems_to_prices
from scrapers.vendors.swift_peptides import scrape_swift_peptides, swift_peptides_to_prices
from scrapers.vendors.true_aminos import scrape_true_aminos, true_aminos_to_prices

SCRAPERS: list[tuple[str, object, object]] = [
    ("Core Peptides", scrape_core_peptides, core_peptides_to_prices),
    ("Swiss Chems", scrape_swiss_chems, swiss_chems_to_prices),
    ("Swift Peptides", scrape_swift_peptides, swift_peptides_to_prices),
    ("Olympex Solutions", scrape_olympex_solutions, olympex_solutions_to_prices),
    ("Eon Peptides", scrape_eon_peptides, eon_peptides_to_prices),
    ("Iron Aminos", scrape_iron_aminos, iron_aminos_to_prices),
    ("Iron Bio Lab", scrape_iron_bio_lab, iron_bio_lab_to_prices),
    ("Peptira", scrape_peptira, peptira_to_prices),
    ("True Amino Labs", scrape_true_aminos, true_aminos_to_prices),
]


def run_paradigm() -> tuple[int, int]:
    from scrapers.vendors.paradigm_peptides import paradigm_to_prices, scrape_paradigm_peptides

    SCRAPERS.append(("Paradigm Peptides", scrape_paradigm_peptides, paradigm_to_prices))
    return 0, 0  # unused


def main() -> int:
    client = get_client()
    dose_map = load_dose_map(client)

    # Peptide Sciences shut down — keep rows but mark unavailable
    mark_vendor_out_of_stock(client, PEPTIDE_SCIENCES_VENDOR_ID)
    print("Peptide Sciences: marked all prices out of stock (vendor closed).")

    include_paradigm = "--with-paradigm" in sys.argv
    scrapers = list(SCRAPERS)
    if include_paradigm:
        from scrapers.vendors.paradigm_peptides import (
            paradigm_to_prices,
            scrape_paradigm_peptides,
        )

        scrapers.append(("Paradigm Peptides", scrape_paradigm_peptides, paradigm_to_prices))
    else:
        print("Skipping Paradigm (Cloudflare). Pass --with-paradigm after: playwright install chromium")

    exit_code = 0
    for name, scrape_fn, map_fn in scrapers:
        try:
            variations = scrape_fn()
            prices, missing = map_fn(variations, dose_map)
            if not variations:
                print(f"{name}: no data parsed (site may have changed).")
                exit_code = 1
                continue
            written = upsert_prices(client, prices)
            vendor_id = prices[0].vendor_id if prices else ""
            mark_out_of_stock(client, vendor_id, missing)
            print(
                f"{name}: parsed {len(variations)} variation(s), "
                f"upserted {written}, marked {len(missing)} OOS."
            )
        except Exception as exc:
            print(f"{name}: FAILED — {exc}")
            exit_code = 1

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
