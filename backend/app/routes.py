from fastapi import APIRouter
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "tactics_analytics.db")

router = APIRouter(prefix="/api/v1", tags=["players"])

@router.get("/players/{player_id}", tags=["players"])
async def get_player_stats(player_id: int, season: str = "2026") -> dict:
    """Get player statistics combined with tactical role evaluation."""
    return {
        "player_id": player_id,
        "season": season,
        "tactical_analysis": {
            "role_classification": "Ball-Playing Defender",
            "strengths": ["High pass completion under pressure", "Aerial dominance"],
            "areas_for_improvement": ["Recovery speed against counter-attacks"],
        },
    }

@router.post("/sync/player", tags=["sync"])
async def sync_player(player: dict) -> dict:
    """Sync player data into the tactics analytics SQLite database."""
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        INSERT OR REPLACE INTO players
        (id, name, age, nationality, team_name, position, games_rating,
         games_appearances, games_minutes, goals_total, goals_assists,
         passes_total, passes_key, passes_accuracy, tackles_total,
         tackles_blocks, duels_total, duels_won)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        player.get("id"),
        player.get("name"),
        player.get("age"),
        player.get("nationality"),
        player.get("team_name"),
        player.get("position"),
        player.get("games_rating"),
        player.get("games_appearances"),
        player.get("games_minutes"),
        player.get("goals_total"),
        player.get("goals_assists"),
        player.get("passes_total"),
        player.get("passes_key"),
        player.get("passes_accuracy"),
        player.get("tackles_total"),
        player.get("tackles_blocks"),
        player.get("duels_total"),
        player.get("duels_won"),
    ))
    conn.commit()
    conn.close()
    return {"status": "synced", "player_id": player.get("id")}

@router.post("/sync/match", tags=["sync"])
async def sync_match(match: dict) -> dict:
    """Sync match data into the tactics analytics SQLite database."""
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        INSERT INTO matches
        (league, home_team, away_team, home_score, away_score, status,
         is_live, match_date, venue_name, venue_city, possession,
         xg_home, xg_away, shots_home, shots_away)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        match.get("league"),
        match.get("home"),
        match.get("away"),
        match.get("homeScore"),
        match.get("awayScore"),
        match.get("status"),
        1 if match.get("isLive") else 0,
        match.get("match_date"),
        match.get("venueName"),
        match.get("venueCity"),
        match.get("possession"),
        match.get("xgHome"),
        match.get("xgAway"),
        match.get("shotsHome"),
        match.get("shotsAway"),
    ))
    conn.commit()
    conn.close()
    return {"status": "synced"}

@router.get("/db/stats", tags=["sync"])
async def db_stats() -> dict:
    """Get row counts from the tactics analytics database."""
    conn = sqlite3.connect(DB_PATH)
    stats = {}
    for table in ["players", "matches", "standings", "weather_cache", "match_xg"]:
        try:
            cursor = conn.execute(f"SELECT COUNT(*) FROM {table}")
            stats[table] = cursor.fetchone()[0]
        except Exception:
            stats[table] = 0
    conn.close()
    return stats