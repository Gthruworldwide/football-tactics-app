"""Langflow client for running flows."""

import logging
from typing import Any, Dict, Optional

import httpx

from mcp_server.config import settings

logger = logging.getLogger(__name__)


class LangflowClient:
    """Client for interacting with Langflow API."""

    def __init__(self) -> None:
        self.base_url = settings.LANGFLOW_BASE_URL.rstrip("/")
        self.api_key = settings.LANGFLOW_API_KEY
        self.flow_id = settings.LANGFLOW_FLOW_ID
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            headers = {"Content-Type": "application/json"}
            if self.api_key:
                headers["Authorization"] = f"Bearer {self.api_key}"
            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                headers=headers,
                timeout=120.0,
            )
        return self._client

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def run_flow(
        self,
        input_value: str,
        tweaks: Optional[Dict[str, Any]] = None,
        session_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Run a Langflow flow with the given input.

        Args:
            input_value: The input text for the flow
            tweaks: Optional tweaks to customize the flow
            session_id: Optional session ID for conversation continuity

        Returns:
            Flow output as dictionary
        """
        if not self.flow_id:
            raise ValueError("LANGFLOW_FLOW_ID not configured")

        client = await self._get_client()

        payload: Dict[str, Any] = {
            "input_value": input_value,
            "output_type": "chat",
            "input_type": "chat",
        }
        if tweaks:
            payload["tweaks"] = tweaks
        if session_id:
            payload["session_id"] = session_id

        try:
            response = await client.post(
                f"/api/v1/run/{self.flow_id}",
                json=payload,
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            logger.error("Langflow API error: %s", e)
            raise
        except Exception as e:
            logger.error("Unexpected error calling Langflow: %s", e)
            raise

    async def health_check(self) -> bool:
        """Check if Langflow is reachable."""
        try:
            client = await self._get_client()
            response = await client.get("/health", timeout=5.0)
            return response.status_code == 200
        except Exception:
            return False
