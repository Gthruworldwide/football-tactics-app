import sqlite3
from pathlib import Path

DB_PATH = Path(r"D:\football-tactics-app\tactics_analytics.db")

def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL;")
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS players (
            player_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            team_id INTEGER,
            team_name TEXT,
            position TEXT,
            nationality TEXT,
            age INTEGER,
            rating REAL,
            goals INTEGER DEFAULT 0,
            assists INTEGER DEFAULT 0,
            xg REAL DEFAULT 0.0,
            xa REAL DEFAULT 0.0,
            photo_url TEXT,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cursor.execute("""
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
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS standings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            league_id INTEGER NOT NULL,
            season INTEGER NOT NULL,
            rank INTEGER NOT NULL,
            team_id INTEGER NOT NULL,
            team_name TEXT NOT NULL,
            played INTEGER DEFAULT 0,
            win INTEGER DEFAULT 0,
            draw INTEGER DEFAULT 0,
            loss INTEGER DEFAULT 0,
            goals_for INTEGER DEFAULT 0,
            goals_against INTEGER DEFAULT 0,
            goal_diff INTEGER DEFAULT 0,
            points INTEGER DEFAULT 0,
            form TEXT,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(league_id, season, team_id)
        )
    """)

    cursor.execute("""
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
    """)

    conn.commit()
    conn.close()

if __name__ == "__main__":
    init_db()
    print(f"Database initialized successfully at: {DB_PATH}")
