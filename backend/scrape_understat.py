import json
import re
import sqlite3
import codecs
from datetime import datetime
from scrapling.fetchers import StealthyFetcher

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
    conn.execute("""
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
    conn.commit()

def extract_js_data(html: str, variable_name: str) -> list[dict]:
    pattern = rf"var\s+{variable_name}\s*=\s*JSON\.parse\('([^']+)'\)"
    match = re.search(pattern, html)
    if not match:
        raise ValueError(f"لم يتم العثور على المتغير {variable_name} في الصفحة.")
    raw_hex = match.group(1)
    decoded_json = codecs.decode(raw_hex, "unicode_escape")
    return json.loads(decoded_json)

def rebuild_league_standings(conn: sqlite3.Connection, league_name: str, season: int = 2026):
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
                "team_name": name, "played": 0, "won": 0, "drawn": 0, "lost": 0,
                "goals_for": 0, "goals_against": 0, "xg_for": 0.0, "xg_against": 0.0,
                "points": 0, "history": []
            }

    for _, h_team, a_team, h_goals, a_goals, h_xg, a_xg in rows:
        ensure_team(h_team)
        ensure_team(a_team)
        h_g, a_g = int(h_goals or 0), int(a_goals or 0)
        h_x, a_x = float(h_xg or 0.0), float(a_xg or 0.0)

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

    sorted_teams = sorted(
        teams.values(),
        key=lambda t: (t["points"], t["goals_for"] - t["goals_against"], t["goals_for"]),
        reverse=True,
    )

    now_iso = datetime.utcnow().isoformat()
    conn.execute("DELETE FROM standings WHERE league = ? AND season = ?", (league_name, season))

    for rank_idx, t in enumerate(sorted_teams, start=1):
        gd = t["goals_for"] - t["goals_against"]
        recent_form = "".join(t["history"][-5:])
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

def scrape_league_data(league_slug: str, league_name: str, season: int = 2026):
    url = f"https://understat.com/league/{league_slug}/{season}"
    print(f"[*] جاري تحميل وتشغيل متصفح خفي لـ {league_name} ({season}) من: {url}")

    try:
        # استخدام StealthyFetcher لتمكين تشغيل JS بالكامل
        page = StealthyFetcher.fetch(url, headless=True, timeout=45)
    except Exception as e:
        print(f"[!] فشل الاتصال المتصفح بـ {league_name}: {e}")
        return

    conn = sqlite3.connect(DB_PATH)
    init_tables(conn)
    now_iso = datetime.utcnow().isoformat()

    # 1. سحب المباريات (datesData)
    try:
        matches = extract_js_data(page.text, "datesData")
        saved_matches = 0
        for m in matches:
            if not m.get("isResult"):
                continue
            uid = int(m["id"])
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
                    updated_at = excluded.updated_at
            """, (
                uid, league_name, season, m.get("datetime", ""),
                m["h"]["title"], m["a"]["title"],
                int(m["goals"]["h"]), int(m["goals"]["a"]),
                round(float(m["xG"]["h"]), 3), round(float(m["xG"]["a"]), 3),
                round(float(m.get("forecast", {}).get("w", 0)), 3),
                round(float(m.get("forecast", {}).get("d", 0)), 3),
                round(float(m.get("forecast", {}).get("l", 0)), 3),
                now_iso
            ))
            saved_matches += 1
        conn.commit()
        rebuild_league_standings(conn, league_name, season)
        print(f"[+] تم حفظ {saved_matches} مباراة لـ {league_name}.")
    except Exception as e:
        print(f"[!] خطأ في سحب مباريات {league_name}: {e}")

    # 2. سحب إحصائيات اللاعبين (playersData)
    try:
        players = extract_js_data(page.text, "playersData")
        saved_players = 0
        for p in players:
            pid = int(p["id"])
            p_name = p["player_name"]
            team_name = p["team_title"]
            position = p.get("position", "")
            games = int(p.get("games", 0))
            mins = int(p.get("time", 0))
            goals = int(p.get("goals", 0))
            assists = int(p.get("assists", 0))
            xg = round(float(p.get("xG", 0.0)), 3)
            xa = round(float(p.get("xA", 0.0)), 3)
            xg_chain = round(float(p.get("xGChain", 0.0)), 3)
            xg_buildup = round(float(p.get("xGBuildup", 0.0)), 3)
            shots = int(p.get("shots", 0))
            key_passes = int(p.get("key_passes", 0))

            conn.execute("""
                INSERT INTO players (
                    understat_id, league, season, player_name, team_name,
                    position, games, minutes, goals, assists,
                    xg, xa, xg_chain, xg_buildup, shots, key_passes, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(understat_id) DO UPDATE SET
                    player_name = excluded.player_name,
                    team_name = excluded.team_name,
                    position = excluded.position,
                    games = excluded.games,
                    minutes = excluded.minutes,
                    goals = excluded.goals,
                    assists = excluded.assists,
                    xg = excluded.xg,
                    xa = excluded.xa,
                    xg_chain = excluded.xg_chain,
                    xg_buildup = excluded.xg_buildup,
                    shots = excluded.shots,
                    key_passes = excluded.key_passes,
                    updated_at = excluded.updated_at
            """, (
                pid, league_name, season, p_name, team_name,
                position, games, mins, goals, assists,
                xg, xa, xg_chain, xg_buildup, shots, key_passes, now_iso
            ))
            saved_players += 1
        conn.commit()
        print(f"[+] تم تحديث إحصائيات {saved_players} لاعباً لـ {league_name}.")
    except Exception as e:
        print(f"[!] خطأ في سحب بيانات لاعبي {league_name}: {e}")

    conn.close()

if __name__ == "__main__":
    for slug, name in LEAGUES.items():
        try:
            scrape_league_data(slug, name, season=2026)
        except Exception as e:
            print(f"[!] خطأ عام في {name}: {e}")
    print("\n[✓] اكتملت عملية السحب والتحديث الشامل لجميع الدوريات عبر المتصفح بنجاح.")
