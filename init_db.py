import sqlite3
import os

DB_PATH = r"D:\football-tactics-app\tactics_analytics.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Players table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS players (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            age INTEGER,
            nationality TEXT,
            team_name TEXT,
            position TEXT,
            games_rating REAL,
            games_appearances INTEGER,
            games_minutes INTEGER,
            goals_total INTEGER,
            goals_assists INTEGER,
            passes_total INTEGER,
            passes_key INTEGER,
            passes_accuracy REAL,
            tackles_total INTEGER,
            tackles_blocks INTEGER,
            duels_total INTEGER,
            duels_won INTEGER,
            updated_at TEXT DEFAULT (datetime('now'))
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

    # Standings table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS standings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            league TEXT,
            rank INTEGER,
            team TEXT,
            played INTEGER,
            gd TEXT,
            pts INTEGER,
            form TEXT,
            updated_at TEXT DEFAULT (datetime('now')),
            UNIQUE(league, team)
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
            match_id TEXT PRIMARY KEY,
            league TEXT,
            home_team TEXT,
            away_team TEXT,
            home_xg REAL,
            away_xg REAL,
            match_date TEXT
        )
    """)

    conn.commit()
    conn.close()
    print(f"Database initialized at {DB_PATH}")

if __name__ == "__main__":
    init_db()
    print("Done!")
