"""MCP Server configuration loaded from environment variables."""

from functools import lru_cache
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    # Langflow
    LANGFLOW_BASE_URL: str = "http://localhost:7860"
    LANGFLOW_API_KEY: str = ""
    LANGFLOW_FLOW_ID: str = ""

    # Ollama
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama3.1:8b"  # or "granite3.1-dense:8b"

    # MCP Server
    MCP_HOST: str = "0.0.0.0"
    MCP_PORT: int = 8001
    DEBUG: bool = False

    # CORS
    CORS_ORIGINS: str = "*"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
