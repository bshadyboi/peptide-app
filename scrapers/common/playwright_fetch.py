from __future__ import annotations

BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)


def fetch_html_playwright(url: str, *, wait_ms: int = 2000) -> str | None:
    """Fetch rendered HTML via headless Chromium (Cloudflare / JS-heavy shops)."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError as exc:
        raise RuntimeError(
            "Playwright required. Run: pip install playwright && playwright install chromium"
        ) from exc

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_context(user_agent=BROWSER_USER_AGENT).new_page()
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=90000)
            page.wait_for_timeout(wait_ms)
            return page.content()
        finally:
            browser.close()

    return None
