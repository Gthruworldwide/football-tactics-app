"""Typed API response schemas shared by the public v1 endpoints."""

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


class TeamInfo(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: Optional[int] = None
    name: Optional[str] = None
    logo: Optional[str] = None
    winner: Optional[bool] = None


class FixtureStatus(BaseModel):
    model_config = ConfigDict(extra="allow")

    long: Optional[str] = None
    short: Optional[str] = None
    elapsed: Optional[int] = None


class FixtureInfo(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: Optional[int] = None
    date: Optional[str] = None
    timezone: Optional[str] = None
    timestamp: Optional[int] = None
    venue: Optional[Dict[str, Any]] = None
    status: FixtureStatus = Field(default_factory=FixtureStatus)


class LeagueInfo(BaseModel):
    model_config = ConfigDict(extra="allow")

    id: Optional[int] = None
    name: Optional[str] = None
    country: Optional[str] = None
    logo: Optional[str] = None
    flag: Optional[str] = None
    season: Optional[int] = None
    round: Optional[str] = None


class GoalsInfo(BaseModel):
    model_config = ConfigDict(extra="allow")

    home: Optional[int] = None
    away: Optional[int] = None


class TacticalXg(BaseModel):
    model_config = ConfigDict(extra="allow")

    home: Optional[float] = None
    away: Optional[float] = None


class MatchResponse(BaseModel):
    """Normalized core fixture fields while preserving provider fields."""

    model_config = ConfigDict(extra="allow")

    fixture: FixtureInfo = Field(default_factory=FixtureInfo)
    league: LeagueInfo = Field(default_factory=LeagueInfo)
    teams: Dict[str, TeamInfo] = Field(default_factory=dict)
    goals: GoalsInfo = Field(default_factory=GoalsInfo)
    score: Dict[str, Any] = Field(default_factory=dict)
    xg: Optional[TacticalXg] = None


class MatchesResponse(BaseModel):
    country_code: str
    season: Optional[int] = None
    matches: List[MatchResponse]


class StandingResponse(BaseModel):
    model_config = ConfigDict(extra="allow")

    rank: Optional[int] = None
    team: Dict[str, Any] = Field(default_factory=dict)
    points: Optional[int] = None
    goalsDiff: Optional[int] = None
    all: Dict[str, Any] = Field(default_factory=dict)
    form: Optional[str] = None


class StandingsResponse(BaseModel):
    country_code: str
    season: Optional[int] = None
    standings: List[StandingResponse]
