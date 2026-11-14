"""Read-only endpoints over the local Understat database (used by the Flutter app)."""

from typing import Optional

from fastapi import APIRouter, Query

from app.core.database import db

router = APIRouter(prefix="/api/tactics", tags=["Tactics Read"])


@router.get("/players")
def players(
    league: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
):
    sql, params = "SELECT * FROM players WHERE 1=1", []
    if league:
        sql += " AND league = ?"
        params.append(league)
    if search:
        sql += " AND (player_name LIKE ? OR team_name LIKE ?)"
        params += [f"%{search}%"] * 2
    sql += " ORDER BY xg DESC, goals DESC LIMIT ?"
    params.append(limit)
    with db() as conn:
        return {"players": [dict(r) for r in conn.execute(sql, params).fetchall()]}


@router.get("/standings")
def standings(league: Optional[str] = None, limit: int = Query(20, ge=1, le=100)):
    with db() as conn:
        if league:
            rows = conn.execute(
                "SELECT * FROM standings WHERE league = ? ORDER BY rank ASC LIMIT ?", (league, limit)
            ).fetchall()
        else:
            rows = conn.execute("SELECT * FROM standings ORDER BY rank ASC LIMIT ?", (limit,)).fetchall()
    return {"standings": [dict(r) for r in rows]}


@router.get("/xg")
def matches_xg(league: Optional[str] = None, limit: int = Query(25, ge=1, le=100)):
    with db() as conn:
        if league:
            xg_rows = conn.execute(
                "SELECT * FROM match_xg WHERE league = ? ORDER BY match_date DESC LIMIT ?", (league, limit)
            ).fetchall()
            fixture_rows = conn.execute(
                """
                SELECT match_id AS understat_id, league_name AS league, season,
                       match_date, home_team, away_team, home_goals, away_goals,
                       home_xg, away_xg, NULL AS forecast_win,
                       NULL AS forecast_draw, NULL AS forecast_loss
                FROM matches WHERE league_name = ?
                ORDER BY match_date DESC LIMIT ?
                """,
                (league, limit),
            ).fetchall()
        else:
            xg_rows = conn.execute(
                "SELECT * FROM match_xg ORDER BY match_date DESC LIMIT ?", (limit,)
            ).fetchall()
            fixture_rows = conn.execute(
                """
                SELECT match_id AS understat_id, league_name AS league, season,
                       match_date, home_team, away_team, home_goals, away_goals,
                       home_xg, away_xg, NULL AS forecast_win,
                       NULL AS forecast_draw, NULL AS forecast_loss
                FROM matches ORDER BY match_date DESC LIMIT ?
                """,
                (limit,),
            ).fetchall()

    def match_key(row):
        return (
            row["league"],
            row["match_date"],
            row["home_team"],
            row["away_team"],
        )

    merged = {match_key(row): dict(row) for row in xg_rows}
    merged.update({match_key(row): dict(row) for row in fixture_rows})
    results = sorted(
        merged.values(),
        key=lambda row: row.get("match_date") or "",
        reverse=True,
    )[:limit]
    return {"matches_xg": results}
