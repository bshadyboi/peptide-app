#!/usr/bin/env python3
"""List and approve/reject crowdsource price submissions."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent / ".env")

from scrapers.db import get_client


def list_pending(client) -> None:
    rows = (
        client.table("price_submissions")
        .select("id, dose_id, vendor_name, price, discount_code, created_at, doses(mg, peptides(name))")
        .eq("status", "pending")
        .order("created_at")
        .execute()
        .data
        or []
    )
    if not rows:
        print("No pending submissions.")
        return
    for row in rows:
        dose = row.get("doses") or {}
        peptide = dose.get("peptides") or {}
        name = peptide.get("name", "?")
        mg = dose.get("mg", "?")
        print(
            f"{row['id']}  {name} {mg}mg  {row.get('vendor_name')}  "
            f"${row.get('price')}  code={row.get('discount_code') or '-'}  "
            f"({row.get('created_at', '')[:10]})"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description="Review crowdsource submissions")
    parser.add_argument("action", choices=["list", "approve", "reject"])
    parser.add_argument("submission_id", nargs="?", help="UUID for approve/reject")
    args = parser.parse_args()

    client = get_client()

    if args.action == "list":
        list_pending(client)
        return 0

    if not args.submission_id:
        print("submission_id required for approve/reject", file=sys.stderr)
        return 1

    fn = "approve_price_submission" if args.action == "approve" else "reject_price_submission"
    result = client.rpc(fn, {"p_submission_id": args.submission_id}).execute()
    if result.data is not None:
        print(result.data)
        return 0
    print("Failed:", result, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
