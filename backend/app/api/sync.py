"""Bulk upsert endpoint and DB stats."""

from typing import List, Optional

from fastapi import APIRouter
from pydantic import BaseModel

from app.core.database import TABLES, db

router = APIRouter(prefix="/api/sync", tags=["Database Sync"])


class PlayerItem(BaseModel):
    understat_id: int
    league: str
    season: int = 2026
    player_name: str
    team_name: str
    position: Optional[str] = None
    games: int = 0
    minutes: int = 0
    goals: int = 0
    assists: int = 0
    xg: float = 0.0
    xa: float = 0.0
    xg_chain: float = 0.0
    xg_buildup: float = 0.0
    shots: int = 0
    key_passes: int = 0


class MatchItem(BaseModel):
    match_id: int
    league_id: Optional[int] = None
    league_name: Optional[str] = None
    season: Optional[int] = 2026
    home_team_id: Optional[int] = None
    home_team: str
    away_team_id: Optional[int] = None
    away_team: str
    home_goals: Optional[int] = None
    away_goals: Optional[int] = None
    home_xg: Optional[float] = None
    away_xg: Optional[float] = None
    status: Optional[str] = "NS"
    venue: Optional[str] = None
    match_date: Optional[str] = None


class StandingItem(BaseModel):
    league: str
    season: int = 2026
    rank: int
    team_name: str
    played: int = 0
    won: int = 0
    drawn: int = 0
    lost: int = 0
    goals_for: int = 0
    goals_against: int = 0
    goal_diff: int = 0
    xg_for: float = 0.0
    xg_against: float = 0.0
    points: int = 0
    form: str = ""


class WeatherItem(BaseModel):
    cache_key: str
    city: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    temperature_c: Optional[float] = None
    wind_speed_kmh: Optional[float] = None
    humidity: Optional[int] = None
    condition_code: Optional[int] = None
    expires_at: Optional[str] = None


class SyncPayload(BaseModel):
    players: List[PlayerItem] = []
    matches: List[MatchItem] = []
    standings: List[StandingItem] = []
    weather: List[WeatherItem] = []


def _upsert(conn, table: str, row: dict, conflict: List[str]) -> None:
    cols = list(row)
    update = ", ".join(f"{c}=excluded.{c}" for c in cols if c not in conflict)
    conn.execute(
        f"INSERT INTO {table} ({', '.join(cols)}, updated_at) "
        f"VALUES ({', '.join('?' * len(cols))}, CURRENT_TIMESTAMP) "
        f"ON CONFLICT({', '.join(conflict)}) DO UPDATE SET {update}, updated_at=CURRENT_TIMESTAMP",
        list(row.values()),
    )


@router.post("/all")
def sync_all(payload: SyncPayload):
    with db() as conn:
        for p in payload.players:
            _upsert(conn, "players", p.model_dump(), ["understat_id"])
        for m in payload.matches:
            _upsert(conn, "matches", m.model_dump(), ["match_id"])
        for s in payload.standings:
            _upsert(conn, "standings", s.model_dump(), ["league", "season", "team_name"])
        for w in payload.weather:
            row = w.model_dump()
            conn.execute(
                "INSERT INTO weather_cache (cache_key, city, latitude, longitude, temperature_c, "
                "wind_speed_kmh, humidity, condition_code, expires_at) VALUES (?,?,?,?,?,?,?,?,?) "
                "ON CONFLICT(cache_key) DO UPDATE SET temperature_c=excluded.temperature_c, "
                "wind_speed_kmh=excluded.wind_speed_kmh, humidity=excluded.humidity, "
                "condition_code=excluded.condition_code, expires_at=excluded.expires_at, "
                "fetched_at=CURRENT_TIMESTAMP",
                list(row.values()),
            )
    return {
        "status": "synced",
        "counts": {k: len(getattr(payload, k)) for k in ("players", "matches", "standings", "weather")},
    }


@router.get("/stats")
def db_stats():
    with db() as conn:
        return {t: conn.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0] for t in TABLES}
