"""Validate current-season coverage without printing the football-data token."""

import asyncio
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.config import settings
from app.services.football_data import FootballDataService


async def main() -> None:
    if not settings.FOOTBALL_DATA_API_KEY:
        raise SystemExit(
            "FOOTBALL_DATA_API_KEY is not configured in the local .env file."
        )

    async with FootballDataService() as api:
        for country_code in ("ENG", "GER", "ITA"):
            competition = api.competition_code(country_code)
            try:
                fixture_payload = await api._get(
                    f"/competitions/{competition}/matches",
                    {"season": settings.API_FOOTBALL_SEASON},
                )
                table_payload = await api._get(
                    f"/competitions/{competition}/standings",
                    {"season": settings.API_FOOTBALL_SEASON},
                )
                matches = fixture_payload.get("matches", [])
                standings = table_payload.get("standings", [])
                table = next(
                    (
                        row.get("table", [])
                        for row in standings
                        if row.get("type") == "TOTAL"
                    ),
                    [],
                )
                dates = sorted(
                    row.get("utcDate", "")
                    for row in matches
                    if row.get("utcDate")
                )
                today = datetime.now(timezone.utc).date().isoformat()
                played = sum(row.get("status") == "FINISHED" for row in matches)
                upcoming = sum(row.get("status") in {"SCHEDULED", "TIMED"} for row in matches)
                print(
                    f"{country_code}/{settings.API_FOOTBALL_SEASON}: "
                    f"{len(matches)} fixtures ({played} finished, {upcoming} scheduled), "
                    f"{len(table)} teams, {dates[0][:10] if dates else 'n/a'}"
                    f" to {dates[-1][:10] if dates else 'n/a'}; "
                    f"today={today}"
                )
            except Exception as exc:
                print(
                    f"{country_code}: check failed "
                    f"({type(exc).__name__}; credentials redacted)"
                )


if __name__ == "__main__":
    asyncio.run(main())
