"""Attach locally-stored Understat xG (scripts/scrape_understat.py) to fixtures."""

from typing import Any, Dict, List

from app.core.database import db


def attach_tactical_metrics(matches: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    with db() as conn:
        for m in matches:
            home = (m.get("teams", {}).get("home") or {}).get("name", "")
            away = (m.get("teams", {}).get("away") or {}).get("name", "")
            row = None
            if home and away:
                row = conn.execute(
                    "SELECT home_xg, away_xg FROM match_xg "
                    "WHERE home_team LIKE ? AND away_team LIKE ? "
                    "ORDER BY match_date DESC LIMIT 1",
                    (f"%{home}%", f"%{away}%"),
                ).fetchone()
            out.append({**m, "xg": {"home": row["home_xg"], "away": row["away_xg"]} if row else None})
    return out
