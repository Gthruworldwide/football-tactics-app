"""Main FastAPI application for the Football Tactics Analytics Engine."""

import asyncio
import os
from functools import lru_cache
from typing import Optional

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import redis
import uvicorn

from app.core.config import settings
from app.core.database import get_redis
from app.services.scrapling_pipeline import ScraplingPipeline
from app.services.api_football import APIFootballService
from app.geolocation import detect_country
from app.routes import router as players_router
from app.sync_router import router as sync_router
from app.read_router import router as read_router

# Initialize Redis
@lru_cache()
def get_redis_client() -> redis.Redis:
    r = redis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT, db=settings.REDIS_DB, decode_responses=True)
    r.ping()
    return r

app = FastAPI(
    title="Football Tactics Analytics Engine",
    description="Minimalist SPA for football analysts and tacticians",
    version="1.0.0",
)

# Include player routes
app.include_router(players_router)

# Include sync routes
app.include_router(sync_router)

# Include read routes
app.include_router(read_router)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health", tags=["health"])
async def health_check():
    return {"status": "healthy", "message": "Football Tactics API is running"}

# Country detection endpoint
@app.get("/api/v1/country/detect", tags=["geo"])
async def detect_country_endpoint(request: Request):
    """Detect user's country via Geo-IP."""
    client_ip = request.client.host
    country = detect_country(client_ip)
    return {"country": country, "country_code": country.upper()[:2]}

# Match data endpoint with caching
@app.get("/api/v1/matches/{country_code}", tags=["matches"])
async def get_matches(
    country_code: str,
    request: Request,
    response: Response,
):
    """Get matches for a specific country with Redis caching."""
    client_ip = request.client.host
    cache_key = f"matches:{country_code}:{client_ip}"
    
    # Check Redis cache first (TTL: 15s live)
    redis_client = get_redis_client()
    cached = redis_client.get(cache_key)
    if cached:
        return JSONResponse(content=cached, status_code=200, headers={"X-Cached": "true"})
    
    # Fetch from API-Football service
    api_service = APIFootballService()
    matches = await api_service.get_fixtures_by_country(country_code)
    
    # Also run scrapling pipeline for tactical metrics
    scrapling = ScraplingPipeline()
    tactical_data = await scrapling.extract_tactical_metrics(matches)
    
    combined_data = {
        "country_code": country_code,
        "matches": matches,
        "tactical_stats": tactical_data,
    }
    
    # Cache for 15 seconds for live data
    redis_client.setex(cache_key, 15, combined_data.model_dump_json())
    
    return JSONResponse(
        content=combined_data.model_dump(),
        status_code=200,
        headers={"X-Cached": "false"},
    )

# Standings endpoint with 24h static cache
@app.get("/api/v1/standings/{country_code}", tags=["standings"])
async def get_standings(country_code: str, response: Response):
    """Get league standings with Redis caching (TTL: 24h static)."""
    cache_key = f"standings:{country_code}"
    
    redis_client = get_redis_client()
    cached = redis_client.get(cache_key)
    if cached:
        return JSONResponse(content=cached, status_code=200, headers={"X-Cached": "true"})
    
    api_service = APIFootballService()
    standings = await api_service.get_standings(country_code)
    
    # Cache for 24 hours for static data
    redis_client.setex(cache_key, 86400, standings.model_dump_json())
    
    return JSONResponse(content=standings.model_dump(), status_code=200, headers={"X-Cached": "false"})

# AI Tactical Summary endpoint
@app.post("/api/v1/tactical/summary", tags=["tactical"])
async def get_tactical_summary(
    match_id: str,
    request: Request,
):
    """Generate AI tactical summary using Langflow + Ollama MCP."""
    from app.services.ai_summary import AITacticalSummary
    
    ai_summary = AITacticalSummary()
    summary = await ai_summary.generate(match_id=match_id, client_ip=request.client.host)
    
    return {"tactical_summary": summary}

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )