import sqlite3
import os

DB_PATH = r"D:\football-tactics-app\tactics_analytics.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Players table (from Understat scraper)
    cursor.execute("""
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
    """)

    # Matches table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS matches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            league TEXT,
            home_team TEXT,
            away_team TEXT,
            home_score INTEGER,
            away_score INTEGER,
            status TEXT,
            is_live INTEGER DEFAULT 0,
            match_date TEXT,
            venue_name TEXT,
            venue_city TEXT,
            possession REAL,
            xg_home TEXT,
            xg_away TEXT,
            shots_home INTEGER,
            shots_away INTEGER,
            updated_at TEXT DEFAULT (datetime('now'))
        )
    """)

    # Standings table (enhanced with xG and form)
    cursor.execute("""
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
    """)

    # Weather cache table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS weather_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            venue_query TEXT UNIQUE,
            temp_c REAL,
            condition TEXT,
            wind_kmh REAL,
            latitude REAL,
            longitude REAL,
            resolved_label TEXT,
            cached_at TEXT DEFAULT (datetime('now'))
        )
    """)

    # Match xG table (from Understat scraper)
    cursor.execute("""
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
    """)

    conn.commit()
    conn.close()
    print(f"Database initialized at {DB_PATH}")

if __name__ == "__main__":
    init_db()
    print("Done!")
