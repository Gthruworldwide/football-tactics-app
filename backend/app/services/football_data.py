"""football-data.org v4 client and the app's canonical football adapters."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

import httpx

from app.core.config import settings

COMPETITIONS: dict[str, str] = {
    "ENG": "PL",
    "EPL": "PL",
    "GB": "PL",
    "GER": "BL1",
    "DE": "BL1",
    "BUNDESLIGA": "BL1",
    "ITA": "SA",
    "IT": "SA",
    "SERIEA": "SA",
    "ESP": "PD",
    "FRA": "FL1",
}

STATUS_CODES = {
    "SCHEDULED": "NS",
    "TIMED": "NS",
    "LIVE": "LIVE",
    "IN_PLAY": "LIVE",
    "PAUSED": "HT",
    "FINISHED": "FT",
    "AWARDED": "FT",
    "POSTPONED": "PST",
    "SUSPENDED": "SUSP",
    "CANCELLED": "CANC",
}


class FootballDataError(Exception):
    """Provider errors surfaced without exposing authentication headers."""


class FootballDataService:
    def __init__(self) -> None:
        if not settings.FOOTBALL_DATA_API_KEY:
            raise FootballDataError("football-data.org API key is not configured.")
        self.client = httpx.AsyncClient(
            base_url=settings.FOOTBALL_DATA_BASE_URL.rstrip("/"),
            headers={"X-Auth-Token": settings.FOOTBALL_DATA_API_KEY},
            timeout=30.0,
        )

    async def __aenter__(self) -> "FootballDataService":
        return self

    async def __aexit__(self, *_: object) -> None:
        await self.client.aclose()

    async def _get(self, path: str, params: dict[str, Any]) -> dict[str, Any]:
        try:
            response = await self.client.get(path, params=params)
            response.raise_for_status()
            payload = response.json()
        except httpx.HTTPStatusError as exc:
            raise FootballDataError(
                f"football-data.org {path} returned HTTP "
                f"{exc.response.status_code}."
            ) from exc
        except (httpx.HTTPError, ValueError) as exc:
            raise FootballDataError(
                f"football-data.org {path} failed ({type(exc).__name__})."
            ) from exc
        if not isinstance(payload, dict):
            raise FootballDataError(f"football-data.org {path} returned invalid data.")
        return payload

    @staticmethod
    def competition_code(country_code: str) -> str:
        try:
            return COMPETITIONS[country_code.upper().replace(" ", "")]
        except KeyError as exc:
            raise FootballDataError(
                f"Unsupported football-data.org league: {country_code}"
            ) from exc

    async def get_fixtures(
        self, country_code: str, season: int
    ) -> list[dict[str, Any]]:
        competition = self.competition_code(country_code)
        payload = await self._get(
            f"/competitions/{competition}/matches", {"season": season}
        )
        rows = payload.get("matches", [])
        if not isinstance(rows, list):
            raise FootballDataError("football-data.org returned an invalid match list.")
        if not rows:
            raise FootballDataError(
                f"No fixtures were returned for {competition} season {season}."
            )
        normalized = [
            self._normalize_match(row, competition)
            for row in rows
            if isinstance(row, dict)
        ]
        return self._relevant_window(normalized)

    @staticmethod
    def _normalize_match(row: dict[str, Any], competition: str) -> dict[str, Any]:
        score = row.get("score") or {}
        full_time = score.get("fullTime") or {}
        regular_time = score.get("regularTime") or {}
        home_score = full_time.get("home", full_time.get("homeTeam"))
        away_score = full_time.get("away", full_time.get("awayTeam"))
        if home_score is None:
            home_score = regular_time.get("home", regular_time.get("homeTeam"))
        if away_score is None:
            away_score = regular_time.get("away", regular_time.get("awayTeam"))
        league = row.get("competition") or {}
        home = row.get("homeTeam") or {}
        away = row.get("awayTeam") or {}
        venue = row.get("venue")
        status = row.get("status") or "UNKNOWN"
        start_date = (row.get("season") or {}).get("startDate")
        try:
            season_year = int(start_date[:4]) if start_date else None
        except (TypeError, ValueError):
            season_year = None
        return {
            "fixture": {
                "id": row.get("id"),
                "date": row.get("utcDate"),
                "timestamp": None,
                "venue": {"name": venue} if venue else None,
                "status": {
                    "long": status.replace("_", " ").title(),
                    "short": STATUS_CODES.get(status, status),
                    "elapsed": row.get("minute"),
                },
            },
            "league": {
                "id": league.get("id"),
                "name": league.get("name") or competition,
                "country": (league.get("area") or {}).get("name"),
                "season": season_year,
                "round": (
                    str(row["matchday"])
                    if row.get("matchday") is not None
                    else None
                ),
            },
            "teams": {
                "home": {
                    "id": home.get("id"),
                    "name": home.get("name"),
                    "logo": home.get("crest") or home.get("crestURI"),
                },
                "away": {
                    "id": away.get("id"),
                    "name": away.get("name"),
                    "logo": away.get("crest") or away.get("crestURI"),
                },
            },
            "goals": {"home": home_score, "away": away_score},
        }

    @staticmethod
    def _relevant_window(matches: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Keep a compact, useful feed: live, next 25, and latest 15 results."""
        now = datetime.now(timezone.utc)

        def kickoff(match: dict[str, Any]) -> datetime | None:
            value = (match.get("fixture") or {}).get("date")
            if not isinstance(value, str):
                return None
            try:
                parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
                return parsed.replace(tzinfo=timezone.utc) if parsed.tzinfo is None else parsed
            except ValueError:
                return None

        live, finished, upcoming = [], [], []
        for match in matches:
            fixture = match.get("fixture") or {}
            status = (fixture.get("status") or {}).get("short")
            date = kickoff(match)
            if status in {"LIVE", "1H", "2H", "HT", "ET", "P"}:
                live.append(match)
            elif status == "FT" and date and date <= now:
                finished.append((date, match))
            elif status in {"NS", "PST"} and date and date >= now:
                upcoming.append((date, match))

        finished.sort(key=lambda item: item[0], reverse=True)
        upcoming.sort(key=lambda item: item[0])
        selected = (
            live
            + [match for _, match in upcoming[:25]]
            + [match for _, match in finished[:15]]
        )
        return selected

    async def get_standings(
        self, country_code: str, season: int
    ) -> list[dict[str, Any]]:
        competition = self.competition_code(country_code)
        payload = await self._get(
            f"/competitions/{competition}/standings", {"season": season}
        )
        standings = payload.get("standings", [])
        if not isinstance(standings, list):
            raise FootballDataError("football-data.org returned an invalid table.")
        total = next(
            (
                item.get("table", [])
                for item in standings
                if isinstance(item, dict) and item.get("type") == "TOTAL"
            ),
            [],
        )
        if not total:
            raise FootballDataError(
                f"No standings table was returned for {competition} season {season}."
            )
        result = []
        for row in total:
            if not isinstance(row, dict):
                continue
            team = row.get("team") or {}
            result.append({
                "rank": row.get("position"),
                "team": {
                    "id": team.get("id"),
                    "name": team.get("name"),
                    "logo": team.get("crest") or team.get("crestURI"),
                },
                "points": row.get("points"),
                "goalsDiff": row.get("goalDifference"),
                "form": row.get("form"),
                "all": {
                    "played": row.get("playedGames"),
                    "win": row.get("won"),
                    "draw": row.get("draw"),
                    "lose": row.get("lost"),
                    "goals": {
                        "for": row.get("goalsFor"),
                        "against": row.get("goalsAgainst"),
                    },
                },
            })
        return result

    async def get_top_scorers(
        self, country_code: str, season: int
    ) -> list[dict[str, Any]]:
        competition = self.competition_code(country_code)
        try:
            payload = await self._get(
                f"/competitions/{competition}/scorers",
                {"season": season, "limit": 50},
            )
        except FootballDataError as exc:
            if "HTTP 403" in str(exc):
                raise FootballDataError(
                    "Top-scorer data is not included in the current "
                    "football-data.org plan."
                ) from exc
            raise
        rows = payload.get("scorers", [])
        if not isinstance(rows, list):
            raise FootballDataError("football-data.org returned an invalid scorers list.")
        players = []
        for row in rows:
            if not isinstance(row, dict):
                continue
            player = row.get("player") or {}
            team = row.get("team") or {}
            players.append({
                "id": player.get("id"),
                "player_name": player.get("name"),
                "team_name": team.get("name"),
                "league": country_code,
                "position": player.get("position"),
                "games": row.get("playedMatches"),
                "minutes": None,
                "goals": row.get("goals"),
                "assists": row.get("assists"),
                "xg": None,
                "xa": None,
                "xg_chain": None,
                "xg_buildup": None,
                "shots": None,
                "key_passes": None,
            })
        return players
