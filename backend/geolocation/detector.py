"""Geo-IP country detection module using IPinfo Lite API."""

import requests
from typing import Optional

# Permanent core countries (non-removable as per blueprint)
PERMANENT_COUNTRIES = ["England", "Spain", "Italy"]

# Example dynamic geo-IP country mapping
GEOIP_COUNTRY_MAP = {
    "Egypt": "Egypt",
    "United States": "United States",
    "Germany": "Germany",
    # ... additional mappings
}


def detect_country(client_ip: str) -> str:
    """
    Detect user's country via IPinfo Lite API.
    
    Args:
        client_ip: The client's IP address
        
    Returns:
        Detected country name
    """
    try:
        response = requests.get(
            f"https://ipinfo.io/{client_ip}/json",
            timeout=5,
        )
        if response.status_code == 200:
            data = response.json()
            country = data.get("country", "")
            if country:
                return country
    except Exception:
        pass
    
    # Default to Egypt as example geo-IP country on fallback
    return "Egypt"


def is_permanent_country(country_name: str) -> bool:
    """Check if a country is one of the 3 permanent core countries."""
    return country_name in PERMANENT_COUNTRIES


def is_allowed_country(country_name: str, allowed_countries: list) -> bool:
    """Check if a country is in the allowed list (5-country filter)."""
    return country_name in allowed_countries


def get_user_country_with_filter(
    client_ip: str,
    allowed_countries: list,
) -> dict:
    """
    Get user's country applying the 5-country strict geographic filter.
    
    Returns:
        dict with country, is_permanent, is_allowed status
    """
    detected = detect_country(client_ip)
    
    return {
        "country": detected,
        "is_permanent": is_permanent_country(detected),
        "is_allowed": is_allowed_country(detected, allowed_countries),
    }