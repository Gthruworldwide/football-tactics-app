import sqlite3
import json
from scrapling.fetchers import StealthyFetcher

DB_PATH = r"D:\football-tactics-app\tactics_analytics.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
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

def scrape_league_xg(league_slug="EPL", season="2026"):
    url = f"https://understat.com/league/{league_slug}/{season}"
    print(f"Fetching tactical xG data from {url}...")
    
    page = StealthyFetcher.fetch(url, headless=True)
    # استخراج بيانات المباريات المدمجة في الصفحة
    scripts = page.css("script")
    dates_data = []
    for s in scripts:
        text = s.text or ""
        if "datesData" in text:
            raw_json = text.split("JSON.parse('")[1].split("')")[0]
            decoded = raw_json.encode('utf-8').decode('unicode_escape')
            dates_data = json.loads(decoded)
            break

    conn = sqlite3.connect(DB_PATH)
    inserted = 0
    for m in dates_data:
        if m.get("isResult"):
            conn.execute("""
                INSERT OR REPLACE INTO match_xg
                (match_id, league, home_team, away_team, home_xg, away_xg, match_date)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                str(m["id"]),
                league_slug,
                m["h"]["title"],
                m["a"]["title"],
                round(float(m["xG"]["h"]), 2),
                round(float(m["xG"]["a"]), 2),
                m["datetime"]
            ))
            inserted += 1
    conn.commit()
    conn.close()
    print(f"Saved {inserted} matches with real xG to tactics_analytics.db")

if __name__ == "__main__":
    init_db()
    for lg in ["EPL", "La_liga", "Serie_A", "Bundesliga", "Ligue_1"]:
        scrape_league_xg(lg, "2026")
