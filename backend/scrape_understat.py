import json
import re
import sqlite3
import codecs
from datetime import datetime
from scrapling.fetchers import Fetcher

DB_PATH = r"D:\football-tactics-app\tactics_analytics.db"

LEAGUES = {
    "EPL": "Premier League",
    "La_liga": "La Liga",
    "Bundesliga": "Bundesliga",
    "Serie_A": "Serie A",
    "Ligue_1": "Ligue 1",
}

def init_tables(conn: sqlite3.Connection):
    conn.execute("""
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
    conn.execute("""
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
    conn.commit()

def extract_dates_data(html: str) -> list[dict]:
    match = re.search(r"var\s+datesData\s*=\s*JSON\.parse\('([^']+)'\)", html)
    if not match:
        raise ValueError("لم يتم العثور على datesData في الصفحة.")
    raw_hex = match.group(1)
    decoded_json = codecs.decode(raw_hex, "unicode_escape")
    return json.loads(decoded_json)

def rebuild_league_standings(conn: sqlite3.Connection, league_name: str, season: int = 2026):
    """حساب وتحديث جدول الترتيب، النقاط، الفارق التهديفي، وآخر 5 نتائج من المباريات المخزنة."""
    rows = conn.execute("""
        SELECT match_date, home_team, away_team, home_goals, away_goals, home_xg, away_xg
        FROM match_xg
        WHERE league = ? AND season = ? AND is_result = 1
        ORDER BY match_date ASC
    """, (league_name, season)).fetchall()

    if not rows:
        return

    teams: dict[str, dict] = {}

    def ensure_team(name: str):
        if name not in teams:
            teams[name] = {
                "team_name": name,
                "played": 0,
                "won": 0,
                "drawn": 0,
                "lost": 0,
                "goals_for": 0,
                "goals_against": 0,
                "xg_for": 0.0,
                "xg_against": 0.0,
                "points": 0,
                "history": [],
            }

    for _, h_team, a_team, h_goals, a_goals, h_xg, a_xg in rows:
        ensure_team(h_team)
        ensure_team(a_team)

        h_g = int(h_goals or 0)
        a_g = int(a_goals or 0)
        h_x = float(h_xg or 0.0)
        a_x = float(a_xg or 0.0)

        teams[h_team]["played"] += 1
        teams[a_team]["played"] += 1

        teams[h_team]["goals_for"] += h_g
        teams[h_team]["goals_against"] += a_g
        teams[a_team]["goals_for"] += a_g
        teams[a_team]["goals_against"] += h_g

        teams[h_team]["xg_for"] += h_x
        teams[h_team]["xg_against"] += a_x
        teams[a_team]["xg_for"] += a_x
        teams[a_team]["xg_against"] += h_x

        if h_g > a_g:
            teams[h_team]["won"] += 1
            teams[h_team]["points"] += 3
            teams[h_team]["history"].append("W")
            teams[a_team]["lost"] += 1
            teams[a_team]["history"].append("L")
        elif h_g < a_g:
            teams[a_team]["won"] += 1
            teams[a_team]["points"] += 3
            teams[a_team]["history"].append("W")
            teams[h_team]["lost"] += 1
            teams[h_team]["history"].append("L")
        else:
            teams[h_team]["drawn"] += 1
            teams[h_team]["points"] += 1
            teams[h_team]["history"].append("D")
            teams[a_team]["drawn"] += 1
            teams[a_team]["points"] += 1
            teams[a_team]["history"].append("D")

    # ترتيب الفرق حسب: النقاط -> فارق الأهداف -> الأهداف المسجلة
    sorted_teams = sorted(
        teams.values(),
        key=lambda t: (t["points"], t["goals_for"] - t["goals_against"], t["goals_for"]),
        reverse=True,
    )

    now_iso = datetime.utcnow().isoformat()
    conn.execute("DELETE FROM standings WHERE league = ? AND season = ?", (league_name, season))

    for rank_idx, t in enumerate(sorted_teams, start=1):
        gd = t["goals_for"] - t["goals_against"]
        recent_form = "".join(t["history"][-5:])  # آخر 5 مباريات مرتبة من الأقدم للأحدث
        conn.execute("""
            INSERT INTO standings (
                league, season, rank, team_name, played, won, drawn, lost,
                goals_for, goals_against, goal_diff, xg_for, xg_against,
                points, form, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            league_name, season, rank_idx, t["team_name"],
            t["played"], t["won"], t["drawn"], t["lost"],
            t["goals_for"], t["goals_against"], gd,
            round(t["xg_for"], 2), round(t["xg_against"], 2),
            t["points"], recent_form, now_iso
        ))

    conn.commit()
    print(f"[+] تم تحديث جدول ترتيب {league_name} ({len(sorted_teams)} فريقاً).")

def scrape_league_xg(league_slug: str, league_name: str, season: int = 2026) -> int:
    url = f"https://understat.com/league/{league_slug}/{season}"
    print(f"[*] جاري سحب بيانات {league_name} ({season}) من: {url}")

    page = Fetcher.get(url, stealthy_headers=True, timeout=30)
    if page.status != 200:
        print(f"[!] فشل الاتصال بـ {league_name} (HTTP {page.status})")
        return 0

    matches = extract_dates_data(page.text)
    conn = sqlite3.connect(DB_PATH)
    init_tables(conn)

    saved_count = 0
    now_iso = datetime.utcnow().isoformat()

    for m in matches:
        if not m.get("isResult"):
            continue

        uid = int(m["id"])
        home_team = m["h"]["title"]
        away_team = m["a"]["title"]
        home_goals = int(m["goals"]["h"])
        away_goals = int(m["goals"]["a"])
        home_xg = round(float(m["xG"]["h"]), 3)
        away_xg = round(float(m["xG"]["a"]), 3)
        match_date = m.get("datetime", "")

        forecast = m.get("forecast", {})
        f_win = round(float(forecast.get("w", 0.0)), 3)
        f_draw = round(float(forecast.get("d", 0.0)), 3)
        f_loss = round(float(forecast.get("l", 0.0)), 3)

        conn.execute("""
            INSERT INTO match_xg (
                understat_id, league, season, match_date,
                home_team, away_team, home_goals, away_goals,
                home_xg, away_xg, forecast_win, forecast_draw, forecast_loss,
                is_result, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
            ON CONFLICT(understat_id) DO UPDATE SET
                home_goals = excluded.home_goals,
                away_goals = excluded.away_goals,
                home_xg = excluded.home_xg,
                away_xg = excluded.away_xg,
                forecast_win = excluded.forecast_win,
                forecast_draw = excluded.forecast_draw,
                forecast_loss = excluded.forecast_loss,
                updated_at = excluded.updated_at
        """, (
            uid, league_name, season, match_date,
            home_team, away_team, home_goals, away_goals,
            home_xg, away_xg, f_win, f_draw, f_loss, now_iso
        ))
        saved_count += 1

    conn.commit()
    rebuild_league_standings(conn, league_name, season)
    conn.close()
    print(f"[+] تم حفظ/تحديث {saved_count} مباراة لـ {league_name}.")
    return saved_count

if __name__ == "__main__":
    total = 0
    for slug, name in LEAGUES.items():
        try:
            total += scrape_league_xg(slug, name, season=2026)
        except Exception as e:
            print(f"[!] خطأ في {name}: {e}")
    print(f"\n[✓] اكتملت العملية بنجاح. إجمالي المباريات المخزنة في match_xg: {total}")
