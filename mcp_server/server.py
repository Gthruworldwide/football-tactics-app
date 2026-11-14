"""MCP Server for the Football Tactics Analytics Engine.

This server integrates Langflow + Ollama with IBM Granite / Llama models
via Model Context Protocol for AI-generated tactical summaries.
"""

import logging
from contextlib import asynccontextmanager
from typing import Any, Dict

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from mcp_server.config import settings
from mcp_server.tactical_summary import TacticalSummaryService

logger = logging.getLogger(__name__)


class MatchData(BaseModel):
    """Match data for tactical summary generation."""
    home_team: str = ""
    away_team: str = ""
    home_goals: int = 0
    away_goals: int = 0
    minute: str = "FT"
    xg: Dict[str, float] = {}
    ppda: Dict[str, float] = {}
    field_tilt: Dict[str, float] = {}
    momentum: str = "Balanced"
    formations: Dict[str, str] = {}
    key_events: list[str] = []
    substitutions: list[str] = []


# Global service instance
summary_service: TacticalSummaryService = None


@asynccontextmanager
async def lifespan(_: FastAPI):
    global summary_service
    summary_service = TacticalSummaryService()
    logger.info("MCP Server started - Tactical summary service initialized")
    yield
    await summary_service.close()
    logger.info("MCP Server shutdown")


app = FastAPI(
    title="MCP Server - Football Tactics Analytics",
    description="Model Context Protocol server for AI tactical analysis",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials="*" not in settings.cors_origins_list,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["health"])
async def health_check():
    """Health check with LLM backend status."""
    llm_status = await summary_service.health_check()
    return {
        "status": "healthy",
        "message": "MCP Server is running",
        "llm_backends": llm_status,
    }


@app.post("/v1/tactical/summary", tags=["tactical"])
async def generate_tactical_summary(match_id: str, match_data: MatchData = None):
    """Generate AI tactical summary using Langflow + Ollama MCP."""
    if match_data is None:
        match_data = MatchData()

    try:
        summary = await summary_service.generate_summary(match_id, match_data.model_dump())
        return {
            "tactical_summary": summary,
            "match_id": match_id,
            "status": "success",
        }
    except Exception as e:
        logger.error("Tactical summary generation failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.MCP_HOST, port=settings.MCP_PORT)
