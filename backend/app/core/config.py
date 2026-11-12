"""Core configuration settings for the Football Tactics Analytics Engine."""

import os
from functools import lru_cache
from pathlib import Path
from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # API Settings
    API_FOOTBALL_KEY: str = Field(default="", env="API_FOOTBALL_KEY")
    API_FOOTBALL_BASE_URL: str = Field(default="https://api-football-v1.p.rapidapi.com/v3", env="API_FOOTBALL_BASE_URL")
    
    # Redis Settings
    REDIS_HOST: str = Field(default="localhost", env="REDIS_HOST")
    REDIS_PORT: int = Field(default=6379, env="REDIS_PORT")
    REDIS_DB: int = Field(default=0, env="REDIS_DB")
    
    # Geo-IP Settings
    IPINFO_TOKEN: str = Field(default="", env="IPINFO_TOKEN")
    
    # CORS Settings
    CORS_ORIGINS: str = Field(default="http://localhost:3000", env="CORS_ORIGINS")
    
    # App Settings
    DEBUG: bool = Field(default=True, env="DEBUG")
    VERSION: str = Field(default="1.0.0", env="VERSION")
    
    # 5-Country Configuration
    PERMANENT_COUNTRIES: List[str] = Field(
        default=["England", "Spain", "Italy"],
        env="PERMANENT_COUNTRIES",
    )
    DYNAMIC_GEOIP_COUNTRY: bool = Field(default=True, env="DYNAMIC_GEOIP_COUNTRY")
    ALLOWED_COUNTRIES: List[str] = Field(
        default=["England", "Spain", "Italy", "Egypt"],  # Egypt as example geo-IP country
        env="ALLOWED_COUNTRIES",
    )
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    settings = Settings()
    return settings


# Resolve settings at module level
settings: Settings = get_settings()