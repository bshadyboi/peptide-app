from __future__ import annotations

import re
import time
from decimal import Decimal

import requests

from scrapers.common.types import ParsedVariation
from scrapers.common.woocommerce import parse_mg

STORE_API = "/wp-json/wc/store/v1/products"


def store_price_to_decimal(raw: str | int, minor_unit: int = 2) -> Decimal:
    value = Decimal(str(raw))
    if minor_unit:
        return value / (Decimal(10) ** minor_unit)
    return value


def mg_from_attributes(attributes: list[dict]) -> Decimal | None:
    for attr in attributes:
        name = (attr.get("name") or "").lower()
        if "size" in name or "strength" in name or "dose" in name:
            for term in attr.get("terms") or []:
                slug = term.get("slug") or term.get("name") or ""
                try:
                    return parse_mg(slug)
                except ValueError:
                    continue
    return None


def fetch_store_product(
    session: requests.Session,
    base_url: str,
    slug: str,
    *,
    retries: int = 3,
) -> dict | None:
    url = f"{base_url.rstrip('/')}{STORE_API}"
    last_error: Exception | None = None

    for attempt in range(retries):
        if attempt > 0:
            time.sleep(min(30, 5 * (2**attempt)))
        response = session.get(url, params={"slug": slug}, timeout=30)
        if response.status_code in (403, 429):
            last_error = requests.HTTPError(f"{response.status_code}", response=response)
            time.sleep(min(60, 10 * (2**attempt)))
            continue
        response.raise_for_status()
        rows = response.json()
        return rows[0] if rows else None

    if last_error:
        raise last_error
    return None


def fetch_store_product_by_id(
    session: requests.Session,
    base_url: str,
    product_id: int,
    *,
    retries: int = 3,
) -> dict | None:
    url = f"{base_url.rstrip('/')}{STORE_API}/{product_id}"
    last_error: Exception | None = None
    for attempt in range(retries):
        if attempt > 0:
            time.sleep(min(30, 5 * (2**attempt)))
        response = session.get(url, timeout=30)
        if response.status_code in (403, 429):
            last_error = requests.HTTPError(f"{response.status_code}", response=response)
            time.sleep(min(60, 10 * (2**attempt)))
            continue
        if response.status_code == 404:
            return None
        response.raise_for_status()
        return response.json()
    if last_error:
        raise last_error
    return None


def _mg_from_variation_attrs(attrs: list[dict]) -> Decimal | None:
    for attr in attrs:
        for key in ("value", "name", "slug"):
            raw = attr.get(key)
            if not raw:
                continue
            try:
                return parse_mg(str(raw))
            except ValueError:
                continue
    return None


def _is_multi_vial_variation(attrs: list[dict]) -> bool:
    for attr in attrs:
        name = (attr.get("name") or "").lower()
        value = (attr.get("value") or attr.get("slug") or "").lower()
        if "vial" in name or "vial" in value:
            if "10 vial" in value or value.startswith("10 "):
                return True
            if "single" in value or "1 vial" in value:
                return False
    return False


def parse_store_variable_product(
    peptide_slug: str,
    product: dict,
    session: requests.Session,
    base_url: str,
    *,
    product_mg: Decimal | None = None,
) -> list[ParsedVariation]:
    """Expand a variable WooCommerce Store API product into per-variation rows."""
    product_url = (product.get("permalink") or "").split("?")[0] or None
    results: list[ParsedVariation] = []

    for index, stub in enumerate(product.get("variations") or []):
        attrs = stub.get("attributes") or []
        if _is_multi_vial_variation(attrs):
            continue
        if index > 0:
            time.sleep(1)
        detail = fetch_store_product_by_id(session, base_url, stub["id"])
        if not detail:
            continue
        mg = product_mg or _mg_from_variation_attrs(attrs)
        parsed = parse_store_product(peptide_slug, detail, mg=mg)
        if parsed:
            parsed.product_url = product_url
            results.append(parsed)

    return results


def scrape_store_catalog(
    session: requests.Session,
    base_url: str,
    products: list[dict],
) -> list[ParsedVariation]:
    """Scrape a vendor catalog via WooCommerce Store API."""
    results: list[ParsedVariation] = []
    for item in products:
        row = fetch_store_product(session, base_url, item["store_slug"])
        if not row:
            continue
        product_url = (row.get("permalink") or "").split("?")[0] or None

        if item.get("variable") or row.get("type") == "variable":
            results.extend(
                parse_store_variable_product(
                    item["peptide_slug"],
                    row,
                    session,
                    base_url,
                    product_mg=item.get("mg"),
                )
            )
            continue

        parsed = parse_store_product(
            item["peptide_slug"],
            row,
            mg=item.get("mg"),
        )
        if parsed:
            parsed.product_url = product_url
            results.append(parsed)

    return results


def parse_store_product(
    peptide_slug: str,
    product: dict,
    *,
    mg: Decimal | None = None,
) -> ParsedVariation | None:
    prices = product.get("prices") or {}
    regular = store_price_to_decimal(
        prices.get("regular_price") or prices.get("price") or "0",
        prices.get("currency_minor_unit", 2),
    )
    sale_raw = prices.get("sale_price")
    sale = (
        store_price_to_decimal(sale_raw, prices.get("currency_minor_unit", 2))
        if sale_raw and sale_raw != prices.get("regular_price")
        else None
    )
    if sale is not None and sale >= regular:
        sale = None

    resolved_mg = mg or mg_from_attributes(product.get("attributes") or [])
    if resolved_mg is None:
        text = (product.get("short_description") or "") + (product.get("description") or "")
        matches = re.findall(r"(\d+(?:\.\d+)?)\s*mg", text, flags=re.I)
        if matches:
            resolved_mg = Decimal(matches[0])
    if resolved_mg is None:
        return None

    return ParsedVariation(
        peptide_slug=peptide_slug,
        mg=resolved_mg,
        price=regular,
        sale_price=sale,
        in_stock=bool(product.get("is_in_stock", False)),
    )
