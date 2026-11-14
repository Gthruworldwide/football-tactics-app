"""Highlightly football-data adapter and normalization helpers."""

from __future__ import annotations

from typing import Any

import httpx

from app.core.config import settings
from app.services.football_data import FootballDataService

LEAGUES: dict[str, tuple[str, str]] = {
    "ENG": ("Premier League", "GB-ENG"),
    "EPL": ("Premier League", "GB-ENG"),
    "GER": ("Bundesliga", "DE"),
    "ITA": ("Serie A", "IT"),
    "ESP": ("La Liga", "ES"),
    "FRA": ("Ligue 1", "FR"),
}


class HighlightlyError(Exception):
    """Raised for provider errors or responses that cannot be normalized."""


class HighlightlyService:
    def __init__(self) -> None:
        if not settings.HIGHLIGHTLY_API_KEY:
            raise HighlightlyError("Highlightly API key is not configured.")
        base_url = settings.HIGHLIGHTLY_BASE_URL.rstrip("/")
        headers = {"x-rapidapi-key": settings.HIGHLIGHTLY_API_KEY}
        if "rapidapi.com" in base_url:
            headers["x-rapidapi-host"] = "football-highlights-api.p.rapidapi.com"
        self.client = httpx.AsyncClient(
            base_url=base_url,
            headers=headers,
            timeout=30.0,
        )

    async def __aenter__(self) -> "HighlightlyService":
        return self

    async def __aexit__(self, *_: object) -> None:
        await self.client.aclose()

    async def _get(self, path: str, params: dict[str, Any]) -> Any:
        try:
            response = await self.client.get(path, params=params)
            response.raise_for_status()
            payload = response.json()
        except httpx.HTTPStatusError as exc:
            # Do not include request headers/credentials in errors or logs.
            raise HighlightlyError(
                f"Highlightly request {path} returned HTTP "
                f"{exc.response.status_code}."
            ) from exc
        except (httpx.HTTPError, ValueError) as exc:
            raise HighlightlyError(
                f"Highlightly request {path} failed ({type(exc).__name__})."
            ) from exc
        if isinstance(payload, dict) and payload.get("statusCode", 200) >= 400:
            raise HighlightlyError(
                str(payload.get("message") or "Highlightly returned an error.")
            )
        return payload

    async def league_id(self, country_code: str, season: int) -> int:
        try:
            name, country = LEAGUES[country_code.upper()]
        except KeyError as exc:
            raise HighlightlyError(
                f"Unsupported Highlightly league: {country_code}"
            ) from exc
        payload = await self._get(
            "/leagues",
            {"leagueName": name, "countryCode": country, "season": season, "limit": 100},
        )
        data = payload.get("data", []) if isinstance(payload, dict) else []
        for item in data:
            if (
                str(item.get("name", "")).casefold() == name.casefold()
                and str((item.get("country") or {}).get("code", "")).upper()
                == country
            ):
                seasons = {
                    int(entry["season"])
                    for entry in item.get("seasons", [])
                    if isinstance(entry, dict) and str(entry.get("season", "")).isdigit()
                }
                league_id = item.get("id")
                if season in seasons and isinstance(league_id, int):
                    return league_id
        raise HighlightlyError(
            f"Highlightly has no {name} league entry for season {season}."
        )

    @staticmethod
    def _rows(payload: Any) -> list[dict[str, Any]]:
        rows = payload.get("data", []) if isinstance(payload, dict) else []
        return [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []

    async def get_fixtures(
        self, country_code: str, season: int
    ) -> list[dict[str, Any]]:
        league_id = await self.league_id(country_code, season)
        payload = await self._get(
            "/matches",
            {"leagueId": league_id, "season": season, "limit": 100, "timezone": "UTC"},
        )
        matches = []
        for item in self._rows(payload):
            league = item.get("league") or {}
            home = item.get("homeTeam") or {}
            away = item.get("awayTeam") or {}
            state = item.get("state") or {}
            current_score = (state.get("score") or {}).get("current")
            home_goals = away_goals = None
            if isinstance(current_score, str) and "-" in current_score:
                left, right = current_score.split("-", 1)
                try:
                    home_goals, away_goals = int(left.strip()), int(right.strip())
                except ValueError:
                    pass
            date = item.get("date")
            description = str(state.get("description") or "")
            matches.append({
                "fixture": {
                    "id": item.get("id"),
                    "date": date,
                    "timestamp": None,
                    "status": {
                        "long": description or None,
                        "short": self._status_code(description),
                        "elapsed": state.get("clock"),
                    },
                },
                "league": {
                    "id": league.get("id", league_id),
                    "name": league.get("name"),
                    "season": league.get("season", season),
                    "round": item.get("round"),
                },
                "teams": {
                    "home": {
                        "id": home.get("id"),
                        "name": home.get("name"),
                        "logo": home.get("logo"),
                    },
                    "away": {
                        "id": away.get("id"),
                        "name": away.get("name"),
                        "logo": away.get("logo"),
                    },
                },
                "goals": {"home": home_goals, "away": away_goals},
            })
        return FootballDataService._relevant_window(matches)

    @staticmethod
    def _status_code(description: str) -> str:
        value = description.casefold().strip()
        if value in {"not started", "to be announced", "scheduled"}:
            return "NS"
        if value in {"first half", "first half extra time"}:
            return "1H"
        if value == "second half":
            return "2H"
        if value in {"half time", "halftime"}:
            return "HT"
        if value in {"extra time", "break time"}:
            return "ET"
        if value in {"penalties", "finished after penalties"}:
            return "P" if value == "penalties" else "FT"
        if value.startswith("finished") or value == "awarded":
            return "FT"
        if value == "postponed":
            return "PST"
        if value in {"cancelled", "canceled"}:
            return "CANC"
        if value == "suspended":
            return "SUSP"
        if value in {"in progress", "unknown"}:
            return "LIVE" if value == "in progress" else "UNKNOWN"
        return description or "UNKNOWN"

    async def get_standings(
        self, country_code: str, season: int
    ) -> list[dict[str, Any]]:
        league_id = await self.league_id(country_code, season)
        payload = await self._get(
            "/standings", {"leagueId": league_id, "season": season}
        )
        groups = payload.get("groups", []) if isinstance(payload, dict) else []
        table = groups[0].get("standings", []) if groups else []
        result = []
        for row in table:
            if not isinstance(row, dict):
                continue
            team = row.get("team") or {}
            total = row.get("total") or {}
            scored = total.get("scoredGoals")
            conceded = total.get("receivedGoals")
            result.append({
                "rank": row.get("position"),
                "team": {
                    "id": team.get("id"),
                    "name": team.get("name"),
                    "logo": team.get("logo"),
                },
                "points": row.get("points"),
                "goalsDiff": (
                    scored - conceded
                    if isinstance(scored, (int, float))
                    and isinstance(conceded, (int, float))
                    else None
                ),
                "all": {
                    "played": total.get("games"),
                    "win": total.get("wins"),
                    "draw": total.get("draws"),
                    "lose": total.get("loses"),
                    "goals": {"for": scored, "against": conceded},
                },
            })
        return result
