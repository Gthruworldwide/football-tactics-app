"""SQLite access layer (single source of truth for the schema)."""

import sqlite3
from contextlib import contextmanager
from pathlib import Path

from app.core.config import settings

DB_PATH = settings.DB_PATH


def get_connection() -> sqlite3.Connection:
    Path(DB_PATH).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL;")
    return conn


@contextmanager
def db():
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


SCHEMA = [
    """
    CREATE TABLE IF NOT EXISTS match_xg (
        understat_id INTEGER PRIMARY KEY,
        league TEXT NOT NULL,
        season INTEGER NOT NULL,
        match_date TEXT,
        home_team TEXT NOT NULL,
        away_team TEXT NOT NULL,
        home_goals INTEGER,
        away_goals INTEGER,
        home_xg REAL,
        away_xg REAL,
        forecast_win REAL,
        forecast_draw REAL,
        forecast_loss REAL,
        is_result INTEGER DEFAULT 1,
        updated_at TEXT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS standings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        league TEXT NOT NULL,
        season INTEGER NOT NULL,
        rank INTEGER NOT NULL,
        team_name TEXT NOT NULL,
        played INTEGER DEFAULT 0,
        won INTEGER DEFAULT 0,
        drawn INTEGER DEFAULT 0,
        lost INTEGER DEFAULT 0,
        goals_for INTEGER DEFAULT 0,
        goals_against INTEGER DEFAULT 0,
        goal_diff INTEGER DEFAULT 0,
        xg_for REAL DEFAULT 0.0,
        xg_against REAL DEFAULT 0.0,
        points INTEGER DEFAULT 0,
        form TEXT DEFAULT '',
        updated_at TEXT,
        UNIQUE(league, season, team_name)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS players (
        understat_id INTEGER PRIMARY KEY,
        league TEXT NOT NULL,
        season INTEGER NOT NULL,
        player_name TEXT NOT NULL,
        team_name TEXT NOT NULL,
        position TEXT,
        games INTEGER DEFAULT 0,
        minutes INTEGER DEFAULT 0,
        goals INTEGER DEFAULT 0,
        assists INTEGER DEFAULT 0,
        xg REAL DEFAULT 0.0,
        xa REAL DEFAULT 0.0,
        xg_chain REAL DEFAULT 0.0,
        xg_buildup REAL DEFAULT 0.0,
        shots INTEGER DEFAULT 0,
        key_passes INTEGER DEFAULT 0,
        updated_at TEXT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS matches (
        match_id INTEGER PRIMARY KEY,
        league_id INTEGER,
        league_name TEXT,
        season INTEGER,
        home_team_id INTEGER,
        home_team TEXT NOT NULL,
        away_team_id INTEGER,
        away_team TEXT NOT NULL,
        home_goals INTEGER,
        away_goals INTEGER,
        home_xg REAL,
        away_xg REAL,
        status TEXT,
        venue TEXT,
        match_date TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS weather_cache (
        cache_key TEXT PRIMARY KEY,
        city TEXT,
        latitude REAL,
        longitude REAL,
        temperature_c REAL,
        wind_speed_kmh REAL,
        humidity INTEGER,
        condition_code INTEGER,
        fetched_at TEXT DEFAULT CURRENT_TIMESTAMP,
        expires_at TEXT
    )
    """,
    "CREATE INDEX IF NOT EXISTS idx_match_xg_teams_date "
    "ON match_xg(home_team, away_team, match_date DESC)",
    "CREATE INDEX IF NOT EXISTS idx_match_xg_league_date "
    "ON match_xg(league, match_date DESC)",
    "CREATE INDEX IF NOT EXISTS idx_players_league_xg "
    "ON players(league, xg DESC)",
    "CREATE INDEX IF NOT EXISTS idx_players_league_name "
    "ON players(league, player_name)",
    "CREATE INDEX IF NOT EXISTS idx_standings_league_season_rank "
    "ON standings(league, season, rank)",
    "CREATE INDEX IF NOT EXISTS idx_matches_league_date "
    "ON matches(league_id, match_date DESC)",
]

TABLES = ["players", "matches", "standings", "weather_cache", "match_xg"]


def init_db() -> str:
    with db() as conn:
        for stmt in SCHEMA:
            conn.execute(stmt)
    return DB_PATH


if __name__ == "__main__":
    print(f"Database initialized at {init_db()}")
