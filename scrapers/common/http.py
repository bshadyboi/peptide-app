from __future__ import annotations

import time

import requests

BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

RETRYABLE_STATUS = {403, 408, 429, 500, 502, 503, 504}


def browser_session() -> requests.Session:
    session = requests.Session()
    session.headers.update(
        {
            "User-Agent": BROWSER_USER_AGENT,
            "Accept": "application/json, text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
        }
    )
    return session


def fetch_html(url: str, session: requests.Session, *, retries: int = 3) -> str | None:
    last_error: Exception | None = None
    for attempt in range(retries):
        if attempt > 0:
            time.sleep(min(45, 4 * (2**attempt)))
        try:
            response = session.get(url, timeout=30)
            if response.status_code == 404:
                return None
            if response.status_code in RETRYABLE_STATUS:
                last_error = requests.HTTPError(
                    f"{response.status_code} for {url}", response=response
                )
                continue
            response.raise_for_status()
            return response.text
        except requests.RequestException as exc:
            last_error = exc
    if last_error:
        raise last_error
    return None
