from fastapi import APIRouter, Query
from typing import Optional
from database import get_connection

router = APIRouter(prefix="/api/tactics", tags=["Tactics Read"])

@router.get("/players")
def get_players_stats(
    league: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(50, le=200),
):
    conn = get_connection()
    query = "SELECT * FROM players WHERE 1=1"
    params: list = []

    if league:
        query += " AND league = ?"
        params.append(league)

    if search:
        query += " AND (player_name LIKE ? OR team_name LIKE ?)"
        like_term = f"%{search}%"
        params.extend([like_term, like_term])

    query += " ORDER BY xg DESC, goals DESC LIMIT ?"
    params.append(limit)

    rows = conn.execute(query, tuple(params)).fetchall()
    conn.close()
    return {"players": [dict(r) for r in rows]}

@router.get("/standings")
def get_standings(league: Optional[str] = None, limit: int = Query(20, le=100)):
    conn = get_connection()
    if league:
        rows = conn.execute(
            "SELECT * FROM standings WHERE league = ? ORDER BY rank ASC LIMIT ?",
            (league, limit)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM standings ORDER BY rank ASC LIMIT ?",
            (limit,)
        ).fetchall()
    conn.close()
    return {"standings": [dict(r) for r in rows]}

@router.get("/xg")
def get_matches_xg(league: Optional[str] = None, limit: int = Query(25, le=100)):
    conn = get_connection()
    if league:
        rows = conn.execute(
            "SELECT * FROM match_xg WHERE league = ? ORDER BY match_date DESC LIMIT ?",
            (league, limit)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM match_xg ORDER BY match_date DESC LIMIT ?",
            (limit,)
        ).fetchall()
    conn.close()
    return {"matches_xg": [dict(r) for r in rows]}
