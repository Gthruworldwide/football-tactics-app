"""Check the API-Football season configured for this local checkout.

This diagnostic intentionally never prints the configured provider key.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[2]
BASE_URL = "https://v3.football.api-sports.io"


def read_key() -> str:
    key = (
        os.environ.get("API_FOOTBALL_KEY")
        or os.environ.get("SPORT_API7_KEY")
        or ""
    ).strip()
    if key:
        return key
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            line = line.lstrip("\ufeff")
            if line.startswith(("API_FOOTBALL_KEY=", "SPORT_API7_KEY=")):
                return line.split("=", 1)[1].strip().strip("\"'")
    return ""


def inspect_season(season: int, key: str) -> dict:
    url = f"{BASE_URL}/standings?{urlencode({'league': 39, 'season': season})}"
    request = Request(url, headers={"x-apisports-key": key, "Accept": "application/json"})
    try:
        with urlopen(request, timeout=20) as response:
            payload = json.load(response)
            return {
                "season": season,
                "http_status": response.status,
                "result_count": payload.get("results"),
                "standings_rows": len(payload.get("response", [])),
                "provider_errors": payload.get("errors"),
            }
    except HTTPError as error:
        try:
            payload = json.loads(error.read().decode("utf-8"))
        except (ValueError, UnicodeDecodeError):
            payload = {}
        return {
            "season": season,
            "http_status": error.code,
            "provider_errors": payload.get("errors", "HTTP request rejected"),
        }
    except (TimeoutError, URLError) as error:
        return {"season": season, "network_error": str(error)}


if __name__ == "__main__":
    api_key = read_key()
    print(f"API_FOOTBALL_KEY configured: {bool(api_key)}")
    if not api_key:
        raise SystemExit("Set API_FOOTBALL_KEY in .env before checking provider access.")
    configured_season = int(os.environ.get("API_FOOTBALL_SEASON", "2026"))
    print(json.dumps(inspect_season(configured_season, api_key), ensure_ascii=False))
