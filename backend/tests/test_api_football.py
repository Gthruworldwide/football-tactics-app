import asyncio

import httpx
import pytest
from fastapi.testclient import TestClient

from app.api import v1
from app.core.config import settings
from app.main import app
from app.services.api_football import (
    APIFootballError,
    APIFootballService,
)


def test_supported_league_aliases_are_explicit():
    assert APIFootballService.league_id("ENG") == 39
    assert APIFootballService.league_id("Bundesliga") == 78
    assert APIFootballService.league_id("Serie A") == 135
    with pytest.raises(APIFootballError, match="Unsupported league"):
        APIFootballService.league_id("not-a-league")


def test_provider_errors_in_http_200_are_not_treated_as_empty_data():
    async def run():
        service = APIFootballService()
        await service.close()

        async def respond(_request):
            return httpx.Response(
                200,
                json={
                    "errors": {"season": "Season not available for this account"},
                    "response": [],
                },
            )

        service.client = httpx.AsyncClient(
            base_url="https://provider.test",
            transport=httpx.MockTransport(respond),
        )
        try:
            with pytest.raises(APIFootballError, match="Season not available"):
                await service._get("/standings", {"league": 39, "season": 2026})
        finally:
            await service.close()

    asyncio.run(run())


def test_free_plan_season_error_falls_back_and_records_actual_season():
    async def run():
        service = APIFootballService()
        await service.close()

        async def respond(request):
            season = request.url.params["season"]
            if season == "2026":
                return httpx.Response(
                    200,
                    json={
                        "errors": {
                            "plan": "Free plans do not have access to this season"
                        },
                        "response": [],
                    },
                )
            return httpx.Response(200, json={"errors": [], "response": []})

        service.client = httpx.AsyncClient(
            base_url="https://provider.test",
            transport=httpx.MockTransport(respond),
        )
        try:
            result = await service._get_for_season(
                "/standings", {"league": 39, "season": 2026}
            )
            assert result == []
            assert service.season_used == 2024
        finally:
            await service.close()

    asyncio.run(run())


def test_fixtures_use_date_filters_not_the_plan_blocked_last_parameter():
    async def run():
        service = APIFootballService()
        await service.close()
        requests = []

        async def respond(request):
            requests.append(request)
            season = request.url.params["season"]
            if season == str(settings.API_FOOTBALL_SEASON):
                return httpx.Response(
                    200,
                    json={
                        "errors": {
                            "plan": "Free plans do not have access to this season"
                        },
                        "response": [],
                    },
                )
            return httpx.Response(200, json={"errors": [], "response": []})

        service.client = httpx.AsyncClient(
            base_url="https://provider.test",
            transport=httpx.MockTransport(respond),
        )
        try:
            fixtures = await service.get_fixtures("ENG")
            assert fixtures == []
            assert service.season_used == 2024
            assert all("last" not in request.url.params for request in requests)
            assert requests[-1].url.params["from"] == "2024-08-01"
            assert requests[-1].url.params["to"] == "2025-06-30"
        finally:
            await service.close()

    asyncio.run(run())


def test_live_players_are_normalized_without_fabricated_xg(monkeypatch):
    class FakeFootballService:
        season_used = 2026

        async def __aenter__(self):
            return self

        async def __aexit__(self, *_args):
            return None

        async def get_top_scorers(self, _country_code):
            return [{
                "player": {"id": 7, "name": "Real Player"},
                "statistics": [{
                    "team": {"name": "Real Club"},
                    "league": {"name": "Bundesliga"},
                    "games": {"position": "Attacker", "appearences": 8, "minutes": 640},
                    "goals": {"total": 6, "assists": 2},
                    "shots": {"total": 21},
                    "passes": {"key": 9},
                }],
            }]

    monkeypatch.setattr(v1, "APIFootballService", FakeFootballService)
    with TestClient(app) as client:
        response = client.get("/api/v1/players/GER")

    assert response.status_code == 200
    player = response.json()["players"][0]
    assert player["player_name"] == "Real Player"
    assert player["team_name"] == "Real Club"
    assert player["goals"] == 6
    assert player["shots"] == 21
    assert player["xg"] is None
    assert player["xa"] is None
