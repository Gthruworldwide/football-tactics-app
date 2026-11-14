import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "test.db")

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


def test_health_and_read_routes():
    with TestClient(app) as c:
        assert c.get("/health").json() == {"status": "healthy"}
        assert c.get("/api/tactics/players").json() == {"players": []}
        assert c.get("/api/tactics/standings").json() == {"standings": []}
        assert c.get("/api/tactics/xg").json() == {"matches_xg": []}


def test_sync_roundtrip():
    payload = {
        "players": [{"understat_id": 1, "league": "EPL", "player_name": "A", "team_name": "T", "xg": 5.5}],
        "matches": [{
            "match_id": 101,
            "league_name": "Premier League",
            "season": 2024,
            "home_team": "Home FC",
            "away_team": "Away FC",
            "home_goals": 2,
            "away_goals": 1,
            "status": "FT",
            "match_date": "2024-08-01T15:00:00Z",
        }],
        "standings": [{"league": "EPL", "rank": 1, "team_name": "T", "points": 9}],
    }
    with TestClient(app) as c:
        assert c.post("/api/sync/all", json=payload).status_code == 200
        assert c.post("/api/sync/all", json=payload).status_code == 200  # idempotent upsert
        assert c.get("/api/tactics/players?league=EPL").json()["players"][0]["player_name"] == "A"
        fixture = c.get("/api/tactics/xg?league=Premier%20League").json()["matches_xg"][0]
        assert fixture["home_team"] == "Home FC"
        assert fixture["home_xg"] is None
        assert c.get("/api/sync/stats").json()["standings"] == 1
