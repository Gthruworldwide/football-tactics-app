from datetime import datetime, timedelta, timezone
import asyncio

from app.api.schemas import MatchesResponse, StandingsResponse
from app.api import v1 as public_api
from app.services.football_data import FootballDataError, FootballDataService
from app.services.highlightly import HighlightlyService


def test_match_normalization_does_not_invent_upcoming_scores():
    match = FootballDataService._normalize_match(
        {
            "id": 42,
            "utcDate": "2026-11-14T18:00:00Z",
            "status": "SCHEDULED",
            "matchday": 12,
            "season": {"startDate": "2026-08-01"},
            "competition": {"id": 2021, "name": "Premier League"},
            "homeTeam": {"id": 1, "name": "Home", "crest": "home.png"},
            "awayTeam": {"id": 2, "name": "Away", "crest": "away.png"},
            "score": {"fullTime": {"home": None, "away": None}},
        },
        "PL",
    )

    assert match["fixture"]["status"]["short"] == "NS"
    assert match["goals"] == {"home": None, "away": None}
    assert match["league"]["season"] == 2026
    assert match["league"]["round"] == "12"
    response = MatchesResponse.model_validate({
        "country_code": "ENG",
        "season": 2026,
        "source": "football-data",
        "matches": [match],
    })
    assert response.matches[0].fixture.status.short == "NS"


def test_live_match_status_and_minute_are_preserved():
    match = FootballDataService._normalize_match(
        {
            "id": 7,
            "utcDate": "2026-11-14T18:00:00Z",
            "status": "IN_PLAY",
            "minute": 63,
            "homeTeam": {"name": "Home"},
            "awayTeam": {"name": "Away"},
        },
        "PL",
    )

    assert match["fixture"]["status"]["short"] == "LIVE"
    assert match["fixture"]["status"]["elapsed"] == 63


def test_finished_scores_parse_football_data_team_suffixed_fields():
    match = FootballDataService._normalize_match(
        {
            "status": "FINISHED",
            "score": {"fullTime": {"homeTeam": 3, "awayTeam": 1}},
            "homeTeam": {"name": "Home"},
            "awayTeam": {"name": "Away"},
        },
        "PL",
    )

    assert match["goals"] == {"home": 3, "away": 1}


def test_highlightly_match_statuses_use_the_same_app_codes():
    assert HighlightlyService._status_code("Not started") == "NS"
    assert HighlightlyService._status_code("First half") == "1H"
    assert HighlightlyService._status_code("Finished after extra time") == "FT"
    assert HighlightlyService._status_code("Postponed") == "PST"


def test_provider_fallback_is_explicit_and_preserves_source(monkeypatch):
    class DownFootballData:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *_):
            pass

        async def get_fixtures(self, *_):
            raise FootballDataError("temporary provider outage")

    class WorkingHighlightly:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *_):
            pass

        async def get_fixtures(self, *_):
            return [{"fixture": {"id": 123}}]

    monkeypatch.setattr(public_api.settings, "FOOTBALL_DATA_API_KEY", "configured")
    monkeypatch.setattr(public_api.settings, "HIGHLIGHTLY_API_KEY", "configured")
    monkeypatch.setattr(public_api, "FootballDataService", DownFootballData)
    monkeypatch.setattr(public_api, "HighlightlyService", WorkingHighlightly)

    fixtures, source = asyncio.run(public_api._load_matches("ENG", 2026, "football-data"))

    assert fixtures == [{"fixture": {"id": 123}}]
    assert source == "highlightly"


def test_provider_engine_rejects_an_older_season_fallback(monkeypatch):
    class DownFootballData:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *_):
            pass

        async def get_fixtures(self, *_):
            raise FootballDataError("unavailable")

    class OldSeasonApiFootball:
        season_used = 2024

        async def __aenter__(self):
            return self

        async def __aexit__(self, *_):
            pass

        async def get_fixtures(self, *_):
            return [{"fixture": {"id": 1}}]

    monkeypatch.setattr(public_api.settings, "FOOTBALL_DATA_API_KEY", "configured")
    monkeypatch.setattr(public_api.settings, "HIGHLIGHTLY_API_KEY", "")
    monkeypatch.setattr(public_api.settings, "API_FOOTBALL_KEY", "configured")
    monkeypatch.setattr(public_api, "FootballDataService", DownFootballData)
    monkeypatch.setattr(public_api, "APIFootballService", OldSeasonApiFootball)

    try:
        asyncio.run(public_api._load_matches("ENG", 2026, "football-data"))
    except Exception as exc:
        assert getattr(exc, "status_code", None) == 502
        assert "2024" in str(exc.detail)
    else:
        raise AssertionError("older-season data must not be served as current")


def test_standings_response_accepts_normalized_provider_row():
    response = StandingsResponse.model_validate({
        "country_code": "GER",
        "season": 2026,
        "standings": [{
            "rank": 1,
            "team": {"id": 10, "name": "Team", "logo": "crest.png"},
            "points": 12,
            "goalsDiff": 7,
            "all": {
                "played": 4,
                "win": 4,
                "draw": 0,
                "lose": 0,
                "goals": {"for": 10, "against": 3},
            },
        }],
    })

    assert response.standings[0].points == 12


def test_relevant_window_keeps_live_next_and_recent_results():
    now = datetime.now(timezone.utc)

    def row(match_id, status, date):
        return {
            "fixture": {
                "id": match_id,
                "date": date.isoformat(),
                "status": {"short": status},
            }
        }

    matches = [
        row(index, "FT", now - timedelta(days=index))
        for index in range(1, 25)
    ]
    matches += [
        row(index + 100, "NS", now + timedelta(days=index))
        for index in range(1, 35)
    ]
    matches.append(row(999, "1H", now))

    selected = FootballDataService._relevant_window(matches)
    ids = {item["fixture"]["id"] for item in selected}

    assert len(ids) == 41
    assert 999 in ids
    assert len(ids.intersection(range(1, 25))) == 15
    assert len(ids.intersection(range(101, 135))) == 25
