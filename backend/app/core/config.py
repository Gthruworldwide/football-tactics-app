"""Application settings loaded from environment variables / .env."""

from functools import lru_cache
from datetime import date
from pathlib import Path

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parents[2]  # backend/


def current_football_season() -> int:
    """Return the season start year for the current July-to-June season."""
    today = date.today()
    return today.year if today.month >= 7 else today.year - 1


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(BASE_DIR.parent / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # API-Football (RapidAPI host or direct api-sports host)
    API_FOOTBALL_KEY: str = Field(
        default="",
        validation_alias=AliasChoices("API_FOOTBALL_KEY", "SPORT_API7_KEY"),
    )
    API_FOOTBALL_BASE_URL: str = "https://api-football-v1.p.rapidapi.com/v3"
    # Can be overridden by API_FOOTBALL_SEASON when a provider account is
    # limited to a specific season. Otherwise follow the current season.
    API_FOOTBALL_SEASON: int = current_football_season()

    # Highlightly / RapidAPI football data. Keep this key on the backend only.
    HIGHLIGHTLY_API_KEY: str = ""
    HIGHLIGHTLY_BASE_URL: str = "https://soccer.highlightly.net"

    # football-data.org v4. The free tier covers fixtures and tables for PL,
    # Bundesliga and Serie A; scorer access depends on the account plan.
    FOOTBALL_DATA_API_KEY: str = ""
    FOOTBALL_DATA_BASE_URL: str = "https://api.football-data.org/v4"

    # Redis (falls back to in-memory fakeredis when unavailable)
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0

    # Geo-IP
    IPINFO_TOKEN: str = ""

    # AI / MCP server
    MCP_BASE_URL: str = "http://localhost:8001"

    # SQLite database
    DB_PATH: str = str(BASE_DIR / "data" / "tactics_analytics.db")

    # CORS: comma-separated origins, or "*"
    CORS_ORIGINS: str = "*"

    DEBUG: bool = False

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
