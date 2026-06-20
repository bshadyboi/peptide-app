#!/usr/bin/env python3
"""Apply vendor rows from migration via Supabase API (service_role)."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scrapers.db import get_client

VENDORS = [
    ("e4000001-0000-4000-8000-000000000005", "Vector Peps", "https://vectorpeps.com", "USA", "Scraper: Cloudflare — pending"),
    ("e4000001-0000-4000-8000-000000000006", "Peptira", "https://peptira.com", "USA", "Scraper: WooCommerce + Cloudflare — pending"),
    ("e4000001-0000-4000-8000-000000000007", "Swift Peptides", "https://swiftpeptides.com", "USA", "Scraper: live"),
    ("e4000001-0000-4000-8000-000000000008", "Olympex Solutions", "https://olympexsolutions.com", "USA", "Scraper: WooCommerce — pending"),
    ("e4000001-0000-4000-8000-000000000009", "PetriTide Science", "https://petratidescience.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000000a", "Arctic Lab Supply", "https://arcticlabsupply.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000000b", "Iron Bio Lab", "https://ironbiolab.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000000c", "Eon Peptides", "https://eonpeptides.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000000d", "SKO Compounds", "https://skocompounds.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000000e", "Hightide Compounds", "https://hightidecompounds.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000000f", "Evo Lab Research", None, None, "URL not found — add when confirmed"),
    ("e4000001-0000-4000-8000-000000000010", "Power Built Labs", "https://powerbuiltlabs.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-000000000011", "True Amino Labs", "https://trueaminolabs.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-000000000012", "Zen Aminos", "https://zenaminos.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-000000000013", "Studz Peptides", "https://studzpeptides.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-000000000014", "Ascending Labs", None, None, "URL not found — add when confirmed"),
    ("e4000001-0000-4000-8000-000000000015", "Chained Aminos", "https://chainedaminos.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-000000000016", "A1 Compounds", None, None, "URL not found — add when confirmed"),
    ("e4000001-0000-4000-8000-000000000017", "Big Box Labs", "https://bigboxlabs.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-000000000018", "Amino Club", "https://aminoclub.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-000000000019", "Iron Aminos", "https://ironaminos.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000001a", "Pacific Edge Labs", "https://pacificedgelabs.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000001b", "Vertex Labs", None, None, "Peptide URL not confirmed"),
    ("e4000001-0000-4000-8000-00000000001c", "Zenith Biopeptides", "https://zenithbiopeptides.com", "USA", "Scraper: pending"),
    ("e4000001-0000-4000-8000-00000000001d", "Planet Peptides", "https://planetpeptide.com", "USA", "Scraper: Cloudflare — pending"),
]


def main() -> int:
    client = get_client()
    rows = [
        {
            "id": vid,
            "name": name,
            "url": url,
            "ships_from": ships_from,
            "notes": notes,
        }
        for vid, name, url, ships_from, notes in VENDORS
    ]
    client.table("vendors").upsert(rows, on_conflict="id").execute()
    print(f"Upserted {len(rows)} vendors.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
