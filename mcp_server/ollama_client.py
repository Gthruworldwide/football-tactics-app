"""Ollama client for local LLM inference."""

import logging
from typing import Any, Dict, List, Optional

import httpx

from mcp_server.config import settings

logger = logging.getLogger(__name__)


class OllamaClient:
    """Client for interacting with Ollama API."""

    def __init__(self) -> None:
        self.base_url = settings.OLLAMA_BASE_URL.rstrip("/")
        self.model = settings.OLLAMA_MODEL
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                headers={"Content-Type": "application/json"},
                timeout=120.0,
            )
        return self._client

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.3,
        max_tokens: int = 500,
    ) -> str:
        """
        Generate text using Ollama.

        Args:
            prompt: User prompt
            system_prompt: Optional system prompt
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate

        Returns:
            Generated text
        """
        client = await self._get_client()

        messages: List[Dict[str, str]] = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens,
            },
        }

        try:
            response = await client.post("/api/chat", json=payload)
            response.raise_for_status()
            data = response.json()
            return data.get("message", {}).get("content", "").strip()
        except httpx.HTTPError as e:
            logger.error("Ollama API error: %s", e)
            raise
        except Exception as e:
            logger.error("Unexpected error calling Ollama: %s", e)
            raise

    async def health_check(self) -> bool:
        """Check if Ollama is reachable and model is available."""
        try:
            client = await self._get_client()
            response = await client.get("/api/tags", timeout=5.0)
            if response.status_code != 200:
                return False
            data = response.json()
            models = [m.get("name", "") for m in data.get("models", [])]
            return any(self.model in m for m in models)
        except Exception:
            return False

    async def pull_model(self) -> bool:
        """Pull the model if not available."""
        try:
            client = await self._get_client()
            response = await client.post(
                "/api/pull", json={"name": self.model}, timeout=300.0
            )
            return response.status_code == 200
        except Exception as e:
            logger.error("Failed to pull model: %s", e)
            return False
