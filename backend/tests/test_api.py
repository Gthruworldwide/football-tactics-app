import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "test.db")

from fastapi.testclient import TestClient  # noqa: E402

from app.api.v1 import _provider_source_uri  # noqa: E402
from app.main import app  # noqa: E402
from app.core.database import db  # noqa: E402
from app.services.knowledge_graph import persist_matches, persist_scorers  # noqa: E402


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


def test_knowledge_search_profile_and_paths_are_source_backed():
    with TestClient(app) as c:
        with db() as conn:
            persist_matches(
                conn,
                [{
                    "fixture": {
                        "id": 701,
                        "date": "2025-08-16T15:00:00Z",
                        "status": {"short": "FT"},
                    },
                    "league": {"id": 39, "name": "Premier League", "season": 2025},
                    "teams": {
                        "home": {"id": 10, "name": "Shared United"},
                        "away": {"id": 11, "name": "Away Club"},
                    },
                    "goals": {"home": 2, "away": 1},
                }],
                "football-data",
                2025,
                "https://api.football-data.org/v4/competitions/PL/matches?season=2025",
            )
            persist_scorers(
                conn,
                [
                    {"id": 91, "player_name": "Alex Smith", "team_id": 10,
                     "team_name": "Shared United", "goals": 5},
                    {"id": 92, "player_name": "Alex Smith", "team_id": 10,
                     "team_name": "Shared United", "goals": 3},
                ],
                "football-data",
                2025,
                "ENG",
                "https://api.football-data.org/v4/competitions/PL/scorers?season=2025",
            )

        search = c.get("/api/v1/knowledge/search", params={"q": "Alex Smith"})
        assert search.status_code == 200
        people = search.json()["entities"]
        assert len(people) == 2  # Same display name, distinct provider identities.
        person_id = people[0]["id"]

        profile = c.get(f"/api/v1/knowledge/entities/{person_id}")
        assert profile.status_code == 200
        person = profile.json()
        assert person["identities"][0]["external_id"] in {"91", "92"}
        assert person["facts"][0]["source"]["provider"] == "football-data"
        assert person["facts"][0]["source"]["season"] == 2025
        assert person["relationships"][0]["predicate"] == "plays_for"

        club_id = person["relationships"][0]["related_entity"]["id"]
        club_profile = c.get(f"/api/v1/knowledge/entities/{club_id}").json()
        competition_id = next(
            relation["related_entity"]["id"]
            for relation in club_profile["relationships"]
            if relation["predicate"] == "competes_in"
        )
        paths = c.get(
            "/api/v1/knowledge/paths",
            params={
                "from_entity_id": person_id,
                "to_entity_id": competition_id,
                "max_depth": 3,
            },
        )
        assert paths.status_code == 200
        path = paths.json()["paths"][0]
        assert [edge["predicate"] for edge in path["relationships"]] == [
            "plays_for",
            "competes_in",
        ]
        assert all(edge["source"]["source_uri"].startswith("https://") for edge in path["relationships"])

        assert c.get("/api/v1/knowledge/entities/not-a-record").status_code == 404


def test_provider_match_response_is_materialized_with_timing_and_source(monkeypatch):
    async def fake_load_matches(country_code, season, preferred):
        assert country_code == "ENG"
        assert season == 2025
        return ([{
            "fixture": {
                "id": 8801,
                "date": "2025-09-01T18:00:00Z",
                "status": {"short": "NS"},
            },
            "league": {"id": 39, "name": "Premier League", "season": 2025},
            "teams": {
                "home": {"id": 810, "name": "Provider City FC"},
                "away": {"id": 811, "name": "Visitor Town"},
            },
            "goals": {"home": None, "away": None},
        }], "football-data")

    monkeypatch.setattr("app.api.v1.settings.API_FOOTBALL_SEASON", 2025)
    monkeypatch.setattr("app.api.v1._load_matches", fake_load_matches)
    monkeypatch.setattr("app.api.v1.cache_get", lambda _key: None)
    monkeypatch.setattr("app.api.v1.cache_set", lambda *_args: None)
    with TestClient(app) as c:
        response = c.get("/api/v1/matches/ENG")
        assert response.status_code == 200
        matches = c.get("/api/v1/knowledge/search", params={"q": "Provider City"})
        club = matches.json()["entities"][0]
        profile = c.get(f"/api/v1/knowledge/entities/{club['id']}").json()
        home_relation = next(
            relation
            for relation in profile["relationships"]
            if relation["predicate"] == "home_team"
        )
        assert home_relation["valid_from"] == "2025-09-01T18:00:00Z"
        assert home_relation["source"]["provider"] == "football-data"
        assert "matches?season=" in home_relation["source"]["source_uri"]
        assert home_relation["source"]["retrieved_at"]


def test_provider_source_references_never_expose_base_url_credentials(monkeypatch):
    monkeypatch.setattr(
        "app.api.v1.settings.API_FOOTBALL_BASE_URL",
        "https://user:password@api.example.test/v3?token=private",
    )
    uri = _provider_source_uri("api-football", "match", "ENG", 2025)
    assert uri == "https://api.example.test/v3/fixtures?league=39&season=2025"
    assert "password" not in uri and "private" not in uri
