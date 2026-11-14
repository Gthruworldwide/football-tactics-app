"""API-Football v3 client."""

from typing import Any, Dict, List, Optional

import httpx

from app.core.config import settings

LEAGUE_IDS: Dict[str, int] = {
    "EG": 233, "EGY": 233,
    "ENG": 39, "GB": 39, "EPL": 39,
    "ESP": 140, "ES": 140, "LALIGA": 140,
    "ITA": 135, "IT": 135, "SERIEA": 135,
    "GER": 78, "DE": 78, "BUNDESLIGA": 78,
    "FRA": 61, "FR": 61, "LIGUE1": 61,
    "SAU": 307, "SA": 307,
}


class APIFootballError(Exception):
    """Raised when API-Football returns an error or is unreachable."""


class APIFootballService:
    def __init__(self) -> None:
        base = settings.API_FOOTBALL_BASE_URL
        if "rapidapi" in base:
            headers = {
                "x-rapidapi-key": settings.API_FOOTBALL_KEY,
                "x-rapidapi-host": "api-football-v1.p.rapidapi.com",
            }
        else:
            headers = {"x-apisports-key": settings.API_FOOTBALL_KEY}
        self.client = httpx.AsyncClient(base_url=base, headers=headers, timeout=30.0)
        self.season_used = settings.API_FOOTBALL_SEASON

    async def __aenter__(self) -> "APIFootballService":
        return self

    async def __aexit__(self, *exc) -> None:
        await self.close()

    async def close(self) -> None:
        await self.client.aclose()

    async def _get(self, path: str, params: Dict[str, Any]) -> List[Dict[str, Any]]:
        try:
            resp = await self.client.get(path, params=params)
            resp.raise_for_status()
            payload = resp.json()
        except httpx.HTTPError as e:
            raise APIFootballError(f"API-Football {path} failed: {e}") from e
        except ValueError as e:
            raise APIFootballError(
                f"API-Football {path} returned invalid JSON"
            ) from e

        errors = payload.get("errors") if isinstance(payload, dict) else None
        if errors:
            # API-Football often reports invalid keys, exhausted quotas, and
            # unavailable seasons in a 200 response. Never treat these as an
            # empty league: doing so made the app silently show fake/blank data.
            details = "; ".join(
                f"{key}: {value}" for key, value in errors.items()
            ) if isinstance(errors, dict) else str(errors)
            raise APIFootballError(f"API-Football rejected {path}: {details}")

        rows = payload.get("response", []) if isinstance(payload, dict) else []
        if not isinstance(rows, list):
            raise APIFootballError(f"API-Football {path} returned an invalid response")
        return rows

    @staticmethod
    def league_id(country_code: str) -> int:
        try:
            return LEAGUE_IDS[country_code.upper().replace(" ", "")]
        except KeyError as e:
            raise APIFootballError(
                f"Unsupported league selection: {country_code}"
            ) from e

    async def _get_for_season(
        self,
        path: str,
        params: Dict[str, Any],
        *,
        use_season_date_range: bool = False,
    ) -> List[Dict[str, Any]]:
        requested_season = int(params["season"])
        candidates = [requested_season]
        if requested_season > 2024:
            # The configured free API plan explicitly rejects seasons after
            # 2024. Try the latest season it may expose, but return its year
            # to clients so older data is never presented as current.
            candidates.extend((2024, 2023, 2022))

        last_season_error: Optional[APIFootballError] = None
        for season in candidates:
            request_params = {**params, "season": season}
            if use_season_date_range:
                request_params["from"] = f"{season}-08-01"
                request_params["to"] = f"{season + 1}-06-30"
            try:
                result = await self._get(path, request_params)
                self.season_used = season
                return result
            except APIFootballError as error:
                message = str(error).lower()
                if "do not have access to this season" not in message:
                    raise
                last_season_error = error

        raise APIFootballError(
            "The provider plan does not expose any supported season "
            "for this league (tried 2022–2024)."
        ) from last_season_error

    async def get_fixtures(
        self,
        country_code: str,
        last: int = 15,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        params: Dict[str, Any] = {
            "league": self.league_id(country_code),
            "season": settings.API_FOOTBALL_SEASON,
        }
        uses_configured_season_range = (
            from_date == f"{settings.API_FOOTBALL_SEASON}-08-01"
            and to_date == f"{settings.API_FOOTBALL_SEASON + 1}-06-01"
        )
        has_custom_range = bool(from_date and to_date) and not uses_configured_season_range
        if has_custom_range:
            params.update({"from": from_date, "to": to_date})
            fixtures = await self._get_for_season("/fixtures", params)
        else:
            fixtures = await self._get_for_season(
                "/fixtures", params, use_season_date_range=True
            )
            if not uses_configured_season_range:
                fixtures.sort(
                    key=lambda row: (row.get("fixture") or {}).get("timestamp") or 0,
                    reverse=True,
                )
                fixtures = fixtures[:last]
        return fixtures

    async def get_standings(self, country_code: str) -> List[Dict[str, Any]]:
        rows = await self._get_for_season(
            "/standings",
            {"league": self.league_id(country_code), "season": settings.API_FOOTBALL_SEASON},
        )
        if not rows:
            return []
        groups = rows[0].get("league", {}).get("standings", [])
        return groups[0] if groups else []

    async def get_top_scorers(self, country_code: str) -> List[Dict[str, Any]]:
        return await self._get_for_season(
            "/players/topscorers",
            {
                "league": self.league_id(country_code),
                "season": settings.API_FOOTBALL_SEASON,
            },
        )

    async def get_lineups(self, fixture_id: int) -> Optional[Dict[str, Any]]:
        rows = await self._get("/fixtures/lineups", {"fixture": fixture_id})
        return rows[0] if rows else None

    async def get_player_ratings(self, fixture_id: int) -> List[Dict[str, Any]]:
        return await self._get("/fixtures/players", {"fixture": fixture_id})
