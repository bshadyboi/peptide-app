from __future__ import annotations

import os
from dataclasses import dataclass
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()

CORE_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-000000000002"
PARADIGM_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-000000000003"
SWISS_CHEMS_VENDOR_ID = "e4000001-0000-4000-8000-000000000004"
VECTOR_PEPS_VENDOR_ID = "e4000001-0000-4000-8000-000000000005"
PEPTIRA_VENDOR_ID = "e4000001-0000-4000-8000-000000000006"
SWIFT_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-000000000007"
OLYMPEX_SOLUTIONS_VENDOR_ID = "e4000001-0000-4000-8000-000000000008"
HIGHTIDE_COMPOUNDS_VENDOR_ID = "e4000001-0000-4000-8000-00000000000e"
TRUE_AMINO_LABS_VENDOR_ID = "e4000001-0000-4000-8000-000000000011"
EON_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-00000000000c"
IRON_BIO_LAB_VENDOR_ID = "e4000001-0000-4000-8000-00000000000b"
IRON_AMINOS_VENDOR_ID = "e4000001-0000-4000-8000-000000000019"
PACIFIC_EDGE_LABS_VENDOR_ID = "e4000001-0000-4000-8000-00000000001a"
PLANET_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-00000000001d"
FUSION_PEPTIDE_VENDOR_ID = "e4000001-0000-4000-8000-00000000001e"
ZENITH_BIOPEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-00000000001c"
POLARIS_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-00000000001f"
LUMI_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-000000000020"
ONEDAY_COMPOUNDS_VENDOR_ID = "e4000001-0000-4000-8000-000000000021"
ALPHA_PEPTIDES_VENDOR_ID = "e4000001-0000-4000-8000-000000000022"
RIPTIDE_WELLNESS_VENDOR_ID = "e4000001-0000-4000-8000-000000000023"
PEPTIDE_SCIENCES_VENDOR_ID = "e4000001-0000-4000-8000-000000000001"


@dataclass
class ScrapedPrice:
    dose_id: str
    vendor_id: str
    price: Decimal
    sale_price: Decimal | None
    in_stock: bool
    discount_code: str | None = None
    coa_available: bool = False
    product_url: str | None = None


def get_client() -> Client:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key or "your-service-role" in key:
        raise RuntimeError(
            "Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in scrapers/.env "
            "(service_role from Supabase Dashboard → API — never commit this file)."
        )
    return create_client(url, key)


def load_dose_map(client: Client) -> dict[tuple[str, Decimal], str]:
    """Map (peptide_slug, mg) → dose_id UUID."""
    rows = (
        client.table("doses")
        .select("id, mg, peptides!inner(slug)")
        .execute()
        .data
        or []
    )
    result: dict[tuple[str, Decimal], str] = {}
    for row in rows:
        slug = row["peptides"]["slug"]
        mg = Decimal(str(row["mg"]))
        result[(slug, mg)] = row["id"]
    return result


def upsert_prices(client: Client, prices: list[ScrapedPrice]) -> int:
    now = datetime.now(timezone.utc).isoformat()
    count = 0
    for row in prices:
        payload: dict[str, Any] = {
            "dose_id": row.dose_id,
            "vendor_id": row.vendor_id,
            "price": float(row.price),
            "sale_price": float(row.sale_price) if row.sale_price is not None else None,
            "in_stock": row.in_stock,
            "discount_code": row.discount_code,
            "coa_available": row.coa_available,
            "source": "scrape",
            "last_seen_at": now,
            "product_url": row.product_url,
        }
        client.table("prices").upsert(payload, on_conflict="dose_id,vendor_id").execute()
        count += 1
    return count


def mark_vendor_out_of_stock(client: Client, vendor_id: str) -> None:
    client.table("prices").update(
        {"in_stock": False, "last_seen_at": datetime.now(timezone.utc).isoformat()}
    ).eq("vendor_id", vendor_id).execute()


def mark_out_of_stock(client: Client, vendor_id: str, dose_ids: list[str]) -> None:
    if not dose_ids:
        return
    client.table("prices").update(
        {"in_stock": False, "last_seen_at": datetime.now(timezone.utc).isoformat()}
    ).eq("vendor_id", vendor_id).in_("dose_id", dose_ids).execute()
