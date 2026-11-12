import logging
import httpx
from typing import Dict, Any

logger = logging.getLogger(__name__)

IPINFO_URL = "https://ipinfo.io/json"

async def detect_country(ip: str = None) -> Dict[str, Any]:
    """
    Detects the user's dynamic location using IPinfo Lite API.
    Defaults to Egypt ('EG') if detection runs locally or offline.
    """
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(IPINFO_URL)
            if response.status_code == 200:
                data = response.json()
                country_code = data.get("country", "EG")
                return {
                    "country_code": country_code,
                    "country_name": data.get("country_name", "Egypt"),
                    "ip": data.get("ip", "127.0.0.1"),
                    "status": "success"
                }
    except Exception as e:
        logger.warning(f"Geo-IP detection fallback triggered: {e}")

    # Fallback to default (Egypt)
    return {
        "country_code": "EG",
        "country_name": "Egypt",
        "ip": "127.0.0.1",
        "status": "fallback"
    }

def detect_country_sync() -> Dict[str, Any]:
    """
    Synchronous helper fallback for country detection.
    """
    return {
        "country_code": "EG",
        "country_name": "Egypt",
        "ip": "127.0.0.1",
        "status": "fallback"
    }