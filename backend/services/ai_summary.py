"""AI Tactical Summary service using Langflow + Ollama MCP."""

import asyncio
from typing import Optional, Dict, Any

import httpx
from pydantic import BaseModel


class AITacticalSummary:
    """Generate AI-generated tactical summaries for TV commentators."""
    
    def __init__(self):
        self.mcp_base_url = "http://localhost:8001"  # MCP server endpoint
        self.client = httpx.AsyncClient(timeout=60.0)
    
    async def generate(self, match_id: str, client_ip: str) -> str:
        """
        Generate an AI tactical summary for a given match.
        
        Args:
            match_id: API-Football match ID
            client_ip: Client IP for Geo-IP country detection
            
        Returns:
            AI-generated tactical summary text
        """
        # First, gather tactical data from various sources
        tactical_data = await self._gather_tactical_data(match_id)
        
        # Build the prompt for the AI model
        prompt = self._build_tactical_prompt(tactical_data, client_ip)
        
        # Query the MCP/Langflow/Ollama setup
        try:
            response = await self.client.post(
                f"{self.mcp_base_url}/v1/chat/completions",
                json={
                    "model": "granite-3.1-2b",
                    "messages": [
                        {"role": "system", "content": "You are an expert football tactician and TV commentator. Provide concise, insightful tactical analysis."},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.3,
                    "max_tokens": 500,
                },
            )
            response.raise_for_status()
            data = response.json()
            return data.get("choices", [{}])[0].get("message", {}).get("content", "Analysis unavailable.")
        except Exception as e:
            logger.error(f"AI summary generation failed: {e}")
            return self._fallback_summary(tactical_data)
    
    async def _gather_tactical_data(self, match_id: str) -> Dict[str, Any]:
        """Gather all available tactical data for a match."""
        # In a full implementation, this would query API-Football, 
        # scrapping pipeline results, and local cache
        return {
            "match_id": match_id,
            "xG": "N/A",  # Would come from scrapping pipeline
            "xA": "N/A",
            "PPDA": "N/A",
            "field_tilt": "50-50",  # Simplified
            "momentum": "Balanced",
        }
    
    def _build_tactical_prompt(self, data: Dict[str, Any], client_ip: str) -> str:
        """Build the AI prompt with tactical data and geo-context."""
        country_info = self._detect_country_from_ip(client_ip)
        
        return f"""
        Generate a tactical summary for a football match (ID: {data['match_id']}) with the following metrics:
        
        - xG (Expected Goals): {data['xG']}
        - xA (Expected Assists): {data['xA']}
        - PPDA (Passes Per Defensive Action): {data['PPDA']}
        - Field Tilt: {data['field_tilt']}
        - Momentum: {data['momentum']}
        
        User's detected country: {country_info}
        
        Provide a concise tactical analysis (2-3 sentences) suitable for a TV commentator,
        focusing on the key tactical insights from the data. Keep it professional and
        analysis-focused. No news, no gossip, purely tactical.
        """
    
    def _detect_country_from_ip(self, client_ip: str) -> str:
        """Detect country from IP for context-aware analysis."""
        try:
            import requests
            resp = requests.get(f"https://ipinfo.io/{client_ip}/json", timeout=5)
            if resp.status_code == 200:
                return resp.json().get("country", "Unknown")
        except Exception:
            pass
        return "Unknown"
    
    def _fallback_summary(self, data: Dict[str, Any]) -> str:
        """Fallback summary when AI service is unavailable."""
        return (
            f"Tactical analysis: The match showed balanced play with "
            f"field tilt at {data.get('field_tilt', 'N/A')}. "
            f"Key metrics indicate {data.get('momentum', 'steady') } momentum "
            f"throughout the game."
        )
    
    async def close(self):
        """Close the HTTP client."""
        await self.client.aclose()