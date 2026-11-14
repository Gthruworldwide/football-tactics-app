"""Geo-IP country detection via ipinfo.io (defaults to Egypt)."""

import ipaddress
import logging
from typing import Any, Dict, Optional

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

DEFAULT = {"country_code": "EG", "country_name": "Egypt", "status": "fallback"}


def _is_public(ip: str) -> bool:
    try:
        return ipaddress.ip_address(ip).is_global
    except ValueError:
        return False


async def detect_country(ip: Optional[str] = None) -> Dict[str, Any]:
    if not ip or not _is_public(ip):
        return {**DEFAULT, "ip": ip or "127.0.0.1"}
    params = {"token": settings.IPINFO_TOKEN} if settings.IPINFO_TOKEN else None
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get(f"https://ipinfo.io/{ip}/json", params=params)
        if resp.status_code == 200:
            data = resp.json()
            code = data.get("country")
            if code:
                return {"country_code": code, "country_name": code, "ip": ip, "status": "success"}
    except Exception as e:
        logger.warning("Geo-IP detection failed: %s", e)
    return {**DEFAULT, "ip": ip}
