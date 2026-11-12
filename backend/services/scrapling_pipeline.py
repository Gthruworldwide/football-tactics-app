"""Scrapling stealth pipeline for extracting tactical metrics from Understat and advanced sources."""

import asyncio
import logging
from typing import List, Dict, Any, Optional

import httpx
from bs4 import BeautifulSoup

from app.core.config import settings

logger = logging.getLogger(__name__)


class ScraplingPipeline:
    """Stealth web scraper for extracting xG, xA, PPDA and other tactical metrics."""
    
    def __init__(self):
        self.client = httpx.AsyncClient(
            timeout=30.0,
            limits=httpx.Limits(max_keepalive_connections=5, max_connections=10),
        )
        self.base_url = "https://understat.com"
    
    async def extract_tactical_metrics(self, matches: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Extract xG, xA, PPDA and other tactical metrics for a list of matches.
        
        Args:
            matches: List of match dictionaries from API-Football
            
        Returns:
            List of match data with added tactical statistics
        """
        results = []
        semaphore = asyncio.Semaphore(3)  # Rate limiting
        
        async def _extract_one(match):
            async with semaphore:
                try:
                    # Understat typically uses team names and match date
                    home_team = match["teams"]["home"]
                    away_team = match["teams"]["away"]
                    # Construct Understat URL format
                    url = f"{self.base_url}/match/{home_team.lower()}-{away_team.lower()}"
                    
                    # Fetch page with stealth headers
                    response = await self.client.get(
                        url,
                        headers={
                            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                            "Accept-Language": "en-US,en;q=0.9",
                        },
                    )
                    
                    if response.status_code != 200:
                        logger.warning(f"Understat returned {response.status_code} for {home_team} vs {away_team}")
                        return {**match, "xG": None, "xA": None, "PPDA": None}
                    
                    soup = BeautifulSoup(response.text, "html.parser")
                    
                    # Extract xG data
                    xG_data = self._parse_xg(soup)
                    
                    # Extract PPDA data
                    ppda_data = self._parse_ppda(soup)
                    
                    # Extract xA data
                    xa_data = self._parse_xa(soup)
                    
                    return {
                        **match,
                        "xG": xG_data,
                        "xA": xa_data,
                        "PPDA": ppda_data,
                    }
                except Exception as e:
                    logger.error(f"Error extracting tactical metrics: {e}")
                    return {**match, "xG": None, "xA": None, "PPDA": None}
        
        # Process matches concurrently with limited concurrency
        tasks = [_extract_one(match) for match in matches]
        results = await asyncio.gather(*tasks, return_exceptions=False)
        
        return results
    
    def _parse_xg(self, soup: BeautifulSoup) -> Optional[Dict[str, float]]:
        """
        Parse xG (Expected Goals) from Understat page.
        
        Returns dict with home_xG and away_xG
        """
        try:
            # Understat uses specific class names for xG data
            xg_elements = soup.find_all("div", {"data-type": "xG"})
            if not xg_elements:
                # Alternative parsing
                xg_elements = soup.find_all("span", class_="xg")
            
            if len(xg_elements) >= 2:
                home_xg = float(xg_elements[0].get_text(strip=True) or "0")
                away_xg = float(xg_elements[1].get_text(strip=True) or "0")
                return {"home_xG": home_xg, "away_xG": away_xg}
            elif len(xg_elements) == 1:
                xg = float(xg_elements[0].get_text(strip=True) or "0")
                return {"home_xG": xg, "away_xG": xg}
        except (ValueError, AttributeError) as e:
            logger.debug(f"xG parse error: {e}")
        
        return {"home_xG": 0.0, "away_xG": 0.0}
    
    def _parse_xa(self, soup: BeautifulSoup) -> Optional[Dict[str, float]]:
        """
        Parse xA (Expected Assists) from Understat page.
        """
        try:
            xa_elements = soup.find_all("span", class_="xa")
            if len(xa_elements) >= 2:
                home_xa = float(xa_elements[0].get_text(strip=True) or "0")
                away_xa = float(xa_elements[1].get_text(strip=True) or "0")
                return {"home_xA": home_xa, "away_xA": away_xa}
        except (ValueError, AttributeError) as e:
            logger.debug(f"xA parse error: {e}")
        
        return {"home_xA": 0.0, "away_xA": 0.0}
    
    def _parse_ppda(self, soup: BeautifulSoup) -> Optional[Dict[str, int]]:
        """
        Parse PPDA (Passes Per Defensive Action) from Understat page.
        """
        try:
            ppda_elements = soup.find_all("div", {"data-type": "ppda"})
            if len(ppda_elements) >= 2:
                home_ppda = int(ppda_elements[0].get_text(strip=True) or "0")
                away_ppda = int(ppda_elements[1].get_text(strip=True) or "0")
                return {"home_PPDA": home_ppda, "away_PPDA": away_ppda}
        except (ValueError, AttributeError) as e:
            logger.debug(f"PPDA parse error: {e}")
        
        return {"home_PPDA": 0, "away_PPDA": 0}
    
    async def close(self):
        """Close the HTTP client."""
        await self.client.aclose()