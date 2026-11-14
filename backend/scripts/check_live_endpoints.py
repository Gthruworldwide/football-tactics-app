"""Smoke-test the configured local API without exposing provider credentials."""

from __future__ import annotations

import json
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

BASE_URL = "http://127.0.0.1:8000/api/v1"
LEAGUES = ("ENG", "GER", "ITA")
ENDPOINTS = {
    "matches": "matches",
    "standings": "standings",
    "players": "players",
}


def check(url: str, endpoint: str) -> str:
    try:
        with urlopen(url, timeout=45) as response:
            data = json.load(response)
            return (
                f"HTTP {response.status}; season={data.get('season')}; "
                f"{len(data.get(endpoint, []))} rows"
            )
    except HTTPError as error:
        try:
            body = json.loads(error.read().decode("utf-8"))
            detail = body.get("detail", "request failed")
        except (ValueError, UnicodeDecodeError):
            detail = "request failed"
        return f"HTTP {error.code}; {detail}"
    except (TimeoutError, URLError) as error:
        return f"network error; {error}"


if __name__ == "__main__":
    for code in LEAGUES:
        for endpoint, route in ENDPOINTS.items():
            print(f"{code} {endpoint}: {check(f'{BASE_URL}/{route}/{code}', endpoint)}")
