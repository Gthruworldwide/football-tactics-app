from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from database import get_connection, init_db

router = APIRouter(prefix="/api/sync", tags=["Database Sync"])

init_db()

class PlayerItem(BaseModel):
    player_id: int
    name: str
    team_id: Optional[int] = None
    team_name: Optional[str] = None
    position: Optional[str] = None
    nationality: Optional[str] = None
    age: Optional[int] = None
    rating: Optional[float] = None
    goals: int = 0
    assists: int = 0
    xg: float = 0.0
    xa: float = 0.0
    photo_url: Optional[str] = None

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
    league_id: int
    season: int
    rank: int
    team_id: int
    team_name: str
    played: int = 0
    win: int = 0
    draw: int = 0
    loss: int = 0
    goals_for: int = 0
    goals_against: int = 0
    goal_diff: int = 0
    points: int = 0
    form: Optional[str] = None

class WeatherCacheItem(BaseModel):
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
    weather: List[WeatherCacheItem] = []

@router.post("/all")
def sync_tactics_data(payload: SyncPayload):
    conn = get_connection()
    cursor = conn.cursor()
    counts = {"players": 0, "matches": 0, "standings": 0, "weather": 0}

    try:
        for p in payload.players:
            cursor.execute("""
                INSERT INTO players (
                    player_id, name, team_id, team_name, position, nationality,
                    age, rating, goals, assists, xg, xa, photo_url, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(player_id) DO UPDATE SET
                    name=excluded.name,
                    team_id=excluded.team_id,
                    team_name=excluded.team_name,
                    position=excluded.position,
                    rating=excluded.rating,
                    goals=excluded.goals,
                    assists=excluded.assists,
                    xg=excluded.xg,
                    xa=excluded.xa,
                    photo_url=excluded.photo_url,
                    updated_at=CURRENT_TIMESTAMP
            """, (
                p.player_id, p.name, p.team_id, p.team_name, p.position,
                p.nationality, p.age, p.rating, p.goals, p.assists,
                p.xg, p.xa, p.photo_url
            ))
            counts["players"] += 1

        for m in payload.matches:
            cursor.execute("""
                INSERT INTO matches (
                    match_id, league_id, league_name, season, home_team_id, home_team,
                    away_team_id, away_team, home_goals, away_goals, home_xg, away_xg,
                    status, venue, match_date, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(match_id) DO UPDATE SET
                    home_goals=excluded.home_goals,
                    away_goals=excluded.away_goals,
                    home_xg=COALESCE(excluded.home_xg, matches.home_xg),
                    away_xg=COALESCE(excluded.away_xg, matches.away_xg),
                    status=excluded.status,
                    updated_at=CURRENT_TIMESTAMP
            """, (
                m.match_id, m.league_id, m.league_name, m.season, m.home_team_id,
                m.home_team, m.away_team_id, m.away_team, m.home_goals, m.away_goals,
                m.home_xg, m.away_xg, m.status, m.venue, m.match_date
            ))
            counts["matches"] += 1

        for s in payload.standings:
            cursor.execute("""
                INSERT INTO standings (
                    league_id, season, rank, team_id, team_name, played, win,
                    draw, loss, goals_for, goals_against, goal_diff, points, form, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT(league_id, season, team_id) DO UPDATE SET
                    rank=excluded.rank,
                    played=excluded.played,
                    win=excluded.win,
                    draw=excluded.draw,
                    loss=excluded.loss,
                    goals_for=excluded.goals_for,
                    goals_against=excluded.goals_against,
                    goal_diff=excluded.goal_diff,
                    points=excluded.points,
                    form=excluded.form,
                    updated_at=CURRENT_TIMESTAMP
            """, (
                s.league_id, s.season, s.rank, s.team_id, s.team_name, s.played,
                s.win, s.draw, s.loss, s.goals_for, s.goals_against, s.goal_diff,
                s.points, s.form
            ))
            counts["standings"] += 1

        for w in payload.weather:
            cursor.execute("""
                INSERT INTO weather_cache (
                    cache_key, city, latitude, longitude, temperature_c,
                    wind_speed_kmh, humidity, condition_code, fetched_at, expires_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
                ON CONFLICT(cache_key) DO UPDATE SET
                    temperature_c=excluded.temperature_c,
                    wind_speed_kmh=excluded.wind_speed_kmh,
                    humidity=excluded.humidity,
                    condition_code=excluded.condition_code,
                    fetched_at=CURRENT_TIMESTAMP,
                    expires_at=excluded.expires_at
            """, (
                w.cache_key, w.city, w.latitude, w.longitude, w.temperature_c,
                w.wind_speed_kmh, w.humidity, w.condition_code, w.expires_at
            ))
            counts["weather"] += 1

        conn.commit()
        return {"status": "synced", "inserted_or_updated": counts}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()
