from __future__ import annotations

import html
import json
import re
from decimal import Decimal, InvalidOperation

from bs4 import BeautifulSoup

from scrapers.common.types import ParsedVariation

VARIATIONS_FORM_SELECTOR = "form.variations_form"


def parse_mg(raw: str) -> Decimal:
    match = re.search(r"(\d+(?:\.\d+)?)", raw.strip().lower())
    if not match:
        raise ValueError(f"Cannot parse mg from: {raw!r}")
    return Decimal(match.group(1))


def parse_price_amount(text: str) -> Decimal | None:
    match = re.search(r"\$?\s*(\d+(?:\.\d{1,2})?)", text.replace(",", ""))
    if not match:
        return None
    return Decimal(match.group(1))


def parse_variations_json(
    peptide_slug: str,
    page_html: str,
    *,
    size_attribute_keys: tuple[str, ...] = (
        "attribute_pa_size",
        "attribute_bpc-157-5mg",
        "attribute_tesamorelin",
        "attribute_ipamorelin",
        "attribute_pa_dose",
    ),
    mg_from_attribute: dict[str, Decimal] | None = None,
) -> list[ParsedVariation]:
    soup = BeautifulSoup(page_html, "html.parser")
    form = soup.select_one(VARIATIONS_FORM_SELECTOR)
    if not form:
        return []

    raw_json = form.get("data-product_variations")
    if not raw_json:
        return []

    variations = json.loads(html.unescape(raw_json))
    parsed: list[ParsedVariation] = []

    for item in variations:
        attrs = item.get("attributes") or {}
        attr_value = None
        attr_key = None
        for key in size_attribute_keys:
            if key in attrs and attrs[key]:
                attr_key = key
                attr_value = attrs[key]
                break
        if not attr_value:
            for key, value in attrs.items():
                if value:
                    attr_key = key
                    attr_value = value
                    break
        if not attr_value:
            continue

        if mg_from_attribute and attr_value in mg_from_attribute:
            mg = mg_from_attribute[attr_value]
        else:
            try:
                mg = parse_mg(attr_value)
            except ValueError:
                continue

        regular = Decimal(str(item.get("display_regular_price", item.get("display_price", 0))))
        display = Decimal(str(item.get("display_price", regular)))
        on_sale = display < regular or bool(item.get("wccs_is_on_sale"))

        parsed.append(
            ParsedVariation(
                peptide_slug=peptide_slug,
                mg=mg,
                price=regular,
                sale_price=display if on_sale else None,
                in_stock=bool(item.get("is_in_stock", False)),
            )
        )

    return parsed


def parse_simple_product(
    peptide_slug: str,
    page_html: str,
    mg: Decimal,
) -> ParsedVariation | None:
    soup = BeautifulSoup(page_html, "html.parser")
    product = soup.select_one("div.product.type-product")
    if not product:
        return None

    price_el = product.select_one("p.price")
    if not price_el:
        return None

    ins = price_el.select_one("ins .woocommerce-Price-amount, ins .amount")
    del_el = price_el.select_one("del .woocommerce-Price-amount, del .amount")
    regular_el = price_el.select_one(".woocommerce-Price-amount, .amount")

    if del_el and ins:
        regular = parse_price_amount(del_el.get_text())
        sale = parse_price_amount(ins.get_text())
    else:
        regular = parse_price_amount(regular_el.get_text() if regular_el else price_el.get_text())
        sale = None

    if regular is None:
        return None

    classes = product.get("class") or []
    in_stock = "outofstock" not in classes and "instock" in classes

    return ParsedVariation(
        peptide_slug=peptide_slug,
        mg=mg,
        price=regular,
        sale_price=sale if sale is not None and sale < regular else None,
        in_stock=in_stock,
    )
