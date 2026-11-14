"""AI tactical summaries via the MCP server (Langflow + Ollama)."""

import logging
from typing import Any, Dict

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


class AITacticalSummary:
    async def generate(self, match_id: str) -> str:
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                resp = await client.post(
                    f"{settings.MCP_BASE_URL}/v1/tactical/summary",
                    params={"match_id": match_id},
                    json={},  # Empty match_data for now, can be extended
                )
            resp.raise_for_status()
            data = resp.json()
            return data.get("tactical_summary") or self._fallback(data)
        except Exception as e:
            logger.error("AI summary generation failed: %s", e)
            return self._fallback({})

    @staticmethod
    def _fallback(data: Dict[str, Any]) -> str:
        return (
            "Tactical analysis unavailable right now. "
            f"Momentum: {data.get('momentum', 'balanced')}."
        )
