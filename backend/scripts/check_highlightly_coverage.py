"""Check configured Highlightly coverage without printing credentials."""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.api.schemas import MatchesResponse, StandingsResponse
from app.core.config import settings
from app.services.highlightly import HighlightlyService


async def main() -> None:
    if not settings.HIGHLIGHTLY_API_KEY:
        raise SystemExit("HIGHLIGHTLY_API_KEY is not configured.")

    for code in ("ENG", "GER", "ITA"):
        try:
            async with HighlightlyService() as api:
                fixtures = await api.get_fixtures(code, settings.API_FOOTBALL_SEASON)
                standings = await api.get_standings(code, settings.API_FOOTBALL_SEASON)
                league_id = await api.league_id(code, settings.API_FOOTBALL_SEASON)
                sample = await api._get(
                    "/matches",
                    {
                        "leagueId": league_id,
                        "season": settings.API_FOOTBALL_SEASON,
                        "limit": 1,
                    },
                )
            MatchesResponse.model_validate({
                "country_code": code,
                "season": settings.API_FOOTBALL_SEASON,
                "matches": fixtures,
            })
            StandingsResponse.model_validate({
                "country_code": code,
                "season": settings.API_FOOTBALL_SEASON,
                "standings": standings,
            })
            fixture_dates = sorted(
                item.get("fixture", {}).get("date", "")
                for item in fixtures
                if item.get("fixture", {}).get("date")
            )
            print(
                f"{code} season {settings.API_FOOTBALL_SEASON}/"
                f"{settings.API_FOOTBALL_SEASON + 1}: "
                f"{len(fixtures)} matches, {len(standings)} standings rows, "
                f"date range {fixture_dates[0][:10] if fixture_dates else 'n/a'}"
                f" to {fixture_dates[-1][:10] if fixture_dates else 'n/a'}, "
                f"provider total {sample.get('pagination', {}).get('totalCount', 'n/a')}, "
                f"plan {sample.get('plan', {}).get('tier', 'n/a')}"
            )
        except Exception as exc:
            # Provider responses and request headers must not be printed here.
            print(f"{code}: coverage check failed ({type(exc).__name__}: {exc})")


if __name__ == "__main__":
    asyncio.run(main())
