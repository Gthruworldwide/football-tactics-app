from fastapi import APIRouter, Query
from typing import Optional
from database import get_connection

router = APIRouter(prefix="/api/tactics", tags=["Tactics Read"])

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
