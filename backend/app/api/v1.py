"""Public API v1: matches, standings, geo, AI summary."""

from urllib.parse import urlencode, urlsplit, urlunsplit

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse

from app.api.schemas import MatchesResponse, StandingsResponse
from app.core.config import settings
from app.core.database import db
from app.core.redis_client import cache_get, cache_set
from app.services.ai_summary import AITacticalSummary
from app.services.api_football import APIFootballError, APIFootballService, LEAGUE_IDS
from app.services.football_data import FootballDataError, FootballDataService
from app.services.highlightly import HighlightlyError, HighlightlyService
from app.services.geolocation import detect_country
from app.services.knowledge_graph import (
    persist_matches,
    persist_scorers,
    persist_standings,
)
from app.services.tactical_metrics import attach_tactical_metrics

router = APIRouter(prefix="/api/v1")


def _client_ip(request: Request) -> str:
    fwd = request.headers.get("x-forwarded-for")
    return fwd.split(",")[0].strip() if fwd else (request.client.host if request.client else "")


def _football_provider() -> str:
    if settings.FOOTBALL_DATA_API_KEY:
        return "football-data"
    if settings.HIGHLIGHTLY_API_KEY:
        return "highlightly"
    return "api-football"


def _provider_source_uri(
    provider: str, record_type: str, country_code: str, season: int
) -> str:
    if provider == "football-data":
        competition = FootballDataService.competition_code(country_code)
        endpoint = {
            "match": "matches",
            "standing": "standings",
            "player_statistics": "scorers",
        }[record_type]
        return _public_source_uri(
            settings.FOOTBALL_DATA_BASE_URL,
            f"competitions/{competition}/{endpoint}",
            {"season": season},
        )
    if provider == "api-football":
        league_id = LEAGUE_IDS[country_code.upper().replace(" ", "")]
        endpoint = {
            "match": "fixtures",
            "standing": "standings",
            "player_statistics": "players/topscorers",
        }[record_type]
        return _public_source_uri(
            settings.API_FOOTBALL_BASE_URL,
            endpoint,
            {"league": league_id, "season": season},
        )
    endpoint = "matches" if record_type == "match" else "standings"
    return _public_source_uri(settings.HIGHLIGHTLY_BASE_URL, endpoint)


def _public_source_uri(
    base_url: str, endpoint: str, query: dict[str, int] | None = None
) -> str:
    parsed = urlsplit(base_url)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        raise ValueError("Provider base URL must be an absolute HTTP(S) URL.")
    hostname = parsed.hostname
    netloc = f"[{hostname}]" if ":" in hostname else hostname
    if parsed.port is not None:
        netloc = f"{netloc}:{parsed.port}"
    path = f"{parsed.path.rstrip('/')}/{endpoint.lstrip('/')}"
    return urlunsplit((parsed.scheme, netloc, path, urlencode(query or {}), ""))


async def _load_matches(cc: str, season: int, preferred: str):
    errors = []
    if preferred == "football-data":
        try:
            async with FootballDataService() as api:
                return await api.get_fixtures(cc, season), "football-data"
        except FootballDataError as exc:
            errors.append(str(exc))
            if settings.HIGHLIGHTLY_API_KEY:
                try:
                    async with HighlightlyService() as api:
                        return await api.get_fixtures(cc, season), "highlightly"
                except HighlightlyError as fallback_exc:
                    errors.append(str(fallback_exc))
    elif preferred == "highlightly":
        try:
            async with HighlightlyService() as api:
                return await api.get_fixtures(cc, season), "highlightly"
        except HighlightlyError as exc:
            errors.append(str(exc))

    if settings.API_FOOTBALL_KEY:
        try:
            async with APIFootballService() as api:
                matches = await api.get_fixtures(cc)
                if api.season_used == season:
                    return matches, "api-football"
                errors.append(
                    f"API-Football only exposed season {api.season_used}, not {season}."
                )
        except APIFootballError as exc:
            errors.append(str(exc))

    if not errors:
        errors.append(f"No configured provider supports {cc} season {season}.")
    raise HTTPException(status_code=502, detail="; ".join(errors))


async def _load_standings(cc: str, season: int, preferred: str):
    errors = []
    if preferred == "football-data":
        try:
            async with FootballDataService() as api:
                return await api.get_standings(cc, season), "football-data"
        except FootballDataError as exc:
            errors.append(str(exc))
            if settings.HIGHLIGHTLY_API_KEY:
                try:
                    async with HighlightlyService() as api:
                        return await api.get_standings(cc, season), "highlightly"
                except HighlightlyError as fallback_exc:
                    errors.append(str(fallback_exc))
    elif preferred == "highlightly":
        try:
            async with HighlightlyService() as api:
                return await api.get_standings(cc, season), "highlightly"
        except HighlightlyError as exc:
            errors.append(str(exc))

    if settings.API_FOOTBALL_KEY:
        try:
            async with APIFootballService() as api:
                table = await api.get_standings(cc)
                if api.season_used == season:
                    return table, "api-football"
                errors.append(
                    f"API-Football only exposed season {api.season_used}, not {season}."
                )
        except APIFootballError as exc:
            errors.append(str(exc))

    if not errors:
        errors.append(f"No configured provider supports {cc} season {season}.")
    raise HTTPException(status_code=502, detail="; ".join(errors))


@router.get("/country/detect", tags=["geo"])
async def country_detect(request: Request):
    return await detect_country(_client_ip(request))


@router.get("/matches/{country_code}", response_model=MatchesResponse, tags=["matches"])
async def get_matches(country_code: str):
    cc = country_code.upper()
    season = settings.API_FOOTBALL_SEASON
    provider = _football_provider()
    key = f"matches:{provider}:{cc}:{season}"
    cached = cache_get(key)
    if cached:
        return JSONResponse(cached, headers={"X-Cached": "true"})
    matches, provider = await _load_matches(cc, season, provider)
    data = {
        "country_code": cc,
        "season": season,
        "source": provider,
        "matches": attach_tactical_metrics(matches),
    }
    with db() as conn:
        persist_matches(
            conn,
            data["matches"],
            provider,
            season,
            _provider_source_uri(provider, "match", cc, season),
        )
    # Use source-specific refresh windows so rapid tab changes do not exhaust
    # a provider's quota. football-data's free scores are delayed; Highlightly
    # advertises one-minute match refreshes.
    matches_ttl = {
        "football-data": 300,
        "highlightly": 60,
        "api-football": 60,
    }.get(provider, 300)
    cache_set(key, data, matches_ttl)
    return JSONResponse(data, headers={"X-Cached": "false"})


@router.get(
    "/standings/{country_code}",
    response_model=StandingsResponse,
    tags=["standings"],
)
async def get_standings(country_code: str):
    cc = country_code.upper()
    season = settings.API_FOOTBALL_SEASON
    provider = _football_provider()
    key = f"standings:{provider}:{cc}:{season}"
    cached = cache_get(key)
    if cached:
        return JSONResponse(cached, headers={"X-Cached": "true"})
    table, provider = await _load_standings(cc, season, provider)
    data = {
        "country_code": cc,
        "season": season,
        "source": provider,
        "standings": table,
    }
    with db() as conn:
        persist_standings(
            conn,
            table,
            provider,
            season,
            cc,
            _provider_source_uri(provider, "standing", cc, season),
        )
    cache_set(key, data, 3600)  # refresh at least hourly during active rounds
    return JSONResponse(data, headers={"X-Cached": "false"})


@router.get("/players/{country_code}", tags=["players"])
async def get_top_scorers(country_code: str):
    cc = country_code.upper()
    season = settings.API_FOOTBALL_SEASON
    provider = _football_provider()
    key = f"players:{provider}:{cc}:{season}"
    cached = cache_get(key)
    if cached:
        return JSONResponse(cached, headers={"X-Cached": "true"})
    try:
        if provider == "football-data":
            try:
                async with FootballDataService() as api:
                    players = await api.get_top_scorers(cc, season)
                data = {
                    "country_code": cc,
                    "season": season,
                    "source": provider,
                    "players": players,
                }
                with db() as conn:
                    persist_scorers(
                        conn,
                        players,
                        provider,
                        season,
                        cc,
                        _provider_source_uri(provider, "player_statistics", cc, season),
                    )
                cache_set(key, data, 3600)
                return JSONResponse(data, headers={"X-Cached": "false"})
            except FootballDataError:
                # A secondary provider is acceptable only if it serves the
                # exact requested season. Never silently downgrade the season.
                if not settings.API_FOOTBALL_KEY:
                    raise
                async with APIFootballService() as api:
                    raw_players = await api.get_top_scorers(cc)
                    if api.season_used != season:
                        raise HTTPException(
                            status_code=502,
                            detail=(
                                "Current-season scorer data is unavailable from "
                                "the configured providers; older-season data was "
                                "deliberately not substituted."
                            ),
                        )
                    season = api.season_used
                    provider = "api-football"
        else:
            async with APIFootballService() as api:
                raw_players = await api.get_top_scorers(cc)
                season = api.season_used
    except (APIFootballError, FootballDataError) as e:
        raise HTTPException(status_code=502, detail=str(e))

    players = []
    for item in raw_players:
        player = item.get("player") or {}
        stats_list = item.get("statistics") or []
        stats = stats_list[0] if stats_list else {}
        games = stats.get("games") or {}
        goals = stats.get("goals") or {}
        shots = stats.get("shots") or {}
        passes = stats.get("passes") or {}
        team = stats.get("team") or {}
        league = stats.get("league") or {}
        players.append({
            "id": player.get("id"),
            "player_name": player.get("name"),
            "team_id": team.get("id"),
            "team_name": team.get("name"),
            "league": league.get("name"),
            "position": games.get("position"),
            "games": games.get("appearences", games.get("appearances")),
            "minutes": games.get("minutes"),
            "goals": goals.get("total"),
            "assists": goals.get("assists"),
            "xg": None,
            "xa": None,
            "xg_chain": None,
            "xg_buildup": None,
            "shots": shots.get("total"),
            "key_passes": passes.get("key"),
        })
    data = {
        "country_code": cc,
        "season": season,
        "source": provider,
        "players": players,
    }
    with db() as conn:
        persist_scorers(
            conn,
            players,
            provider,
            season,
            cc,
            _provider_source_uri(provider, "player_statistics", cc, season),
        )
    cache_set(key, data, 3600)
    cache_set(f"players:{provider}:{cc}:{season}", data, 3600)
    return JSONResponse(data, headers={"X-Cached": "false"})


@router.post("/tactical/summary", tags=["tactical"])
async def tactical_summary(match_id: str):
    return {"tactical_summary": await AITacticalSummary().generate(match_id)}
