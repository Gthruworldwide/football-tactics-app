"""Populate the local analytics database from API-Football fixtures.

API-Football fixture feeds do not guarantee xG values, so absent xG is stored
as NULL rather than being misrepresented as zero.
"""

import asyncio
import sqlite3
from typing import Any

from app.core.config import settings
from app.core.database import DB_PATH, init_db
from app.services.api_football import APIFootballService


COUNTRIES = {
    "EG": ("Egyptian Premier League", 233),
    "ENG": ("Premier League", 39),
    "ESP": ("La Liga", 140),
    "ITA": ("Serie A", 135),
}


def _value(value: Any, default: Any = None) -> Any:
    return default if value is None else value


async def sync() -> int:
    init_db()
    saved = 0

    async with APIFootballService() as api:
        with sqlite3.connect(DB_PATH) as conn:
            # Migrate fixture-only rows written by the earlier version of this
            # script out of match_xg. That table is reserved for real xG data.
            legacy_leagues = [name for name, _ in COUNTRIES.values()]
            placeholders = ", ".join("?" for _ in legacy_leagues)
            legacy_rows = conn.execute(
                f"""
                SELECT understat_id, league, season, match_date, home_team,
                       away_team, home_goals, away_goals
                FROM match_xg
                WHERE home_xg = 0 AND away_xg = 0
                  AND forecast_win IS NULL
                  AND forecast_draw IS NULL
                  AND forecast_loss IS NULL
                  AND season = ?
                  AND league IN ({placeholders})
                """,
                (settings.API_FOOTBALL_SEASON, *legacy_leagues),
            ).fetchall()
            league_ids = {name: league_id for name, league_id in COUNTRIES.values()}
            for row in legacy_rows:
                conn.execute(
                    """
                    INSERT INTO matches (
                        match_id, league_id, league_name, season, home_team,
                        away_team, home_goals, away_goals, status, match_date
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'FT', ?)
                    ON CONFLICT(match_id) DO NOTHING
                    """,
                    (
                        row[0], league_ids.get(row[1]), row[1], row[2], row[4],
                        row[5], row[6], row[7], row[3],
                    ),
                )
            if legacy_rows:
                conn.executemany(
                    "DELETE FROM match_xg WHERE understat_id = ?",
                    [(row[0],) for row in legacy_rows],
                )

            for country_code, (league_name, league_id) in COUNTRIES.items():
                fixtures = await api.get_fixtures(
                    country_code,
                    from_date=f"{settings.API_FOOTBALL_SEASON}-08-01",
                    to_date=f"{settings.API_FOOTBALL_SEASON + 1}-06-01",
                )
                for fixture in fixtures:
                    fixture_info = fixture.get("fixture") or {}
                    league = fixture.get("league") or {}
                    teams = fixture.get("teams") or {}
                    goals = fixture.get("goals") or {}
                    home = (teams.get("home") or {}).get("name") or "Home"
                    away = (teams.get("away") or {}).get("name") or "Away"
                    fixture_id = fixture_info.get("id")

                    if not fixture_id:
                        continue

                    conn.execute(
                        """
                        INSERT INTO matches (
                            match_id, league_id, league_name, season, home_team,
                            away_team, home_goals, away_goals, status, venue, match_date
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT(match_id) DO UPDATE SET
                            league_id=excluded.league_id,
                            league_name=excluded.league_name,
                            season=excluded.season,
                            home_team=excluded.home_team,
                            away_team=excluded.away_team,
                            home_goals=excluded.home_goals,
                            away_goals=excluded.away_goals,
                            status=excluded.status,
                            venue=excluded.venue,
                            updated_at=CURRENT_TIMESTAMP
                        """,
                        (
                            int(fixture_id),
                            league.get("id") or league_id,
                            league_name,
                            settings.API_FOOTBALL_SEASON,
                            home,
                            away,
                            _value(goals.get("home"), 0),
                            _value(goals.get("away"), 0),
                            ((fixture_info.get("status") or {}).get("short") or "NS"),
                            ((fixture_info.get("venue") or {}).get("name")),
                            fixture_info.get("date"),
                        ),
                    )
                    saved += 1
            conn.commit()

    return saved


if __name__ == "__main__":
    print(f"Saved {asyncio.run(sync())} fixtures to {DB_PATH}")
