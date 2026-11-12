"""API-Football service for live scores, lineups, and player ratings."""

import httpx
from typing import List, Optional, Dict, Any

from app.core.config import settings


class APIFootballService:
    """Service class for interacting with API-Football v3."""
    
    def __init__(self):
        self.base_url = settings.API_FOOTBALL_BASE_URL
        self.api_key = settings.API_FOOTBALL_KEY
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            headers={
        "x-rapidapi-key": self.api_key,
        "x-rapidapi-host": "api-football-v1.p.rapidapi.com",
            },
            timeout=30.0,
        )
    
    async def get_fixtures_by_country(self, country_code: str) -> List[Dict[str, Any]]:
        """
        Get football fixtures for a specific country.
        
        Args:
            country_code: Country code (e.g., "ENG", "ESP", "ITA")
            
        Returns:
            List of match dictionaries
        """
        try:
            # Map country codes to league IDs or use country search
            # This is a simplified version - full implementation would
            # search for leagues in the specified country
            response = await self.client.get(
                "/fixtures",
                params={
                    "status": "LIVE",
                    "league": "39",  # Default to Premier League as fallback
                },
            )
            response.raise_for_status()
            data = response.json()
            return data.get("response", [])
        except httpx.HTTPError as e:
            raise RuntimeError(f"API-Football request failed: {e}")
    
    async def get_standings(self, country_code: str) -> List[Dict[str, Any]]:
        """
        Get league standings for a specific country.
        
        Args:
            country_code: Country code (e.g., "ENG", "ESP", "ITA")
            
        Returns:
            List of standings entries
        """
        try:
            # Map country codes to league IDs
            league_map = {
                "ENG": 39,   # Premier League
                "ESP": 140,  # La Liga
                "ITA": 135,  # Serie A
            }
            league_id = league_map.get(country_code, 39)
            
            response = await self.client.get(
                "/leagues/standings",
                params={
                    "league": league_id,
                    "season": "2024",  # Current season
                },
            )
            response.raise_for_status()
            data = response.json()
            return data.get("standings", [])[0] if data.get("standings") else []
        except httpx.HTTPError as e:
            raise RuntimeError(f"API-Football standings request failed: {e}")
    
    async def get_lineups(self, fixture_id: int) -> Optional[Dict[str, Any]]:
        """
        Get lineups for a specific fixture.
        
        Args:
            fixture_id: API-Football fixture ID
            
        Returns:
            Lineup data or None
        """
        try:
            response = await self.client.get(
                "/fixtures lineups",
                params={"fixture": fixture_id},
            )
            response.raise_for_status()
            return response.json().get("response", [{}])[0]
        except httpx.HTTPError as e:
            raise RuntimeError(f"API-Football lineups request failed: {e}")
    
    async def get_player_ratings(self, fixture_id: int) -> Optional[List[Dict[str, Any]]]:
        """
        Get player ratings for a specific fixture.
        
        Args:
            fixture_id: API-Football fixture ID
            
        Returns:
            List of player ratings or None
        """
        try:
            response = await self.client.get(
                "/fixtures/lineups",
                params={"fixture": fixture_id},
            )
            response.raise_for_status()
            data = response.json()
            return data.get("response", [{}])[0].get("lineups", {}).get("ratings", [])
        except httpx.HTTPError as e:
            raise RuntimeError(f"API-Football player ratings request failed: {e}")
    
    async def close(self):
        """Close the HTTP client."""
        await self.client.aclose()


class RuntimeError(Exception):
    """Custom exception for API-Football errors."""
    pass