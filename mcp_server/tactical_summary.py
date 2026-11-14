"""Tactical summary generation using Langflow + Ollama."""

import logging
from typing import Any, Dict, Optional

from mcp_server.config import settings
from mcp_server.langflow_client import LangflowClient
from mcp_server.ollama_client import OllamaClient

logger = logging.getLogger(__name__)


# System prompt for tactical football analysis
TACTICAL_SYSTEM_PROMPT = """You are an expert football tactical analyst providing concise summaries for TV commentators.

Your task: Generate a 2-3 sentence tactical summary based on match data.

Focus on:
- Team shape and formation changes
- Key tactical battles (press vs build-up, wing play, set pieces)
- Momentum shifts and their causes
- xG/shot quality vs actual goals
- Substitutions and their impact

Style: Professional, concise, commentator-ready. No fluff. No markdown.
Language: English (can be translated by frontend).

Example:
"Liverpool's high press forced 3 first-half turnovers leading to 2.1 xG, but Salah's missed chances kept it 1-0. At 60', Slot switched to 4-4-2 dropping Nunez deeper, neutralizing Arsenal's inverted fullbacks. Momentum shifted at 75' when Martinelli's introduction stretched the backline, creating 2 big chances."
"""


class TacticalSummaryService:
    """Service for generating AI tactical summaries."""

    def __init__(self) -> None:
        self.langflow = LangflowClient()
        self.ollama = OllamaClient()
        self._use_langflow = bool(settings.LANGFLOW_FLOW_ID)

    async def close(self) -> None:
        await self.langflow.close()
        await self.ollama.close()

    async def generate_summary(
        self,
        match_id: str,
        match_data: Dict[str, Any],
    ) -> str:
        """
        Generate tactical summary for a match.

        Args:
            match_id: Unique match identifier
            match_data: Match data including scores, xG, events, lineups, etc.

        Returns:
            Tactical summary string
        """
        prompt = self._build_prompt(match_data)

        if self._use_langflow:
            try:
                return await self._generate_via_langflow(prompt, match_id)
            except Exception as e:
                logger.warning("Langflow failed, falling back to Ollama: %s", e)

        # Fallback to direct Ollama
        return await self._generate_via_ollama(prompt)

    def _build_prompt(self, data: Dict[str, Any]) -> str:
        """Build structured prompt from match data."""
        home = data.get("home_team", "Home")
        away = data.get("away_team", "Away")
        score = f"{data.get('home_goals', 0)}-{data.get('away_goals', 0)}"
        minute = data.get("minute", "FT")
        xg = data.get("xg", {})
        xg_str = "xG: " + str(xg.get('home', '?')) + " - " + str(xg.get('away', '?')) if xg else "xG: N/A"
        ppda = data.get("ppda", {})
        ppda_str = "PPDA: " + str(ppda.get('home', '?')) + " - " + str(ppda.get('away', '?')) if ppda else "PPDA: N/A"
        field_tilt = data.get("field_tilt", {})
        tilt_str = "Field Tilt: " + str(field_tilt.get('home', '?')) + "% - " + str(field_tilt.get('away', '?')) + "%" if field_tilt else "Field Tilt: N/A"
        momentum = data.get("momentum", "Balanced")
        events = data.get("key_events", [])
        events_str = "; ".join(events) if events else "No key events"
        formations = data.get("formations", {})
        form_str = "Formations: " + home + " " + str(formations.get('home', '?')) + ", " + away + " " + str(formations.get('away', '?'))
        subs = data.get("substitutions", [])
        subs_str = "; ".join(subs) if subs else "No subs"

        return "Match: " + home + " vs " + away + " (" + score + ", " + minute + "')\n" + xg_str + "\n" + ppda_str + "\n" + tilt_str + "\nMomentum: " + momentum + "\n" + form_str + "\nKey Events: " + events_str + "\nSubstitutions: " + subs_str + "\n---\nGenerate tactical summary:"

    async def _generate_via_langflow(self, prompt: str, match_id: str) -> str:
        """Generate summary using Langflow."""
        result = await self.langflow.run_flow(
            input_value=prompt,
            tweaks={
                "system_prompt": TACTICAL_SYSTEM_PROMPT,
            },
            session_id="match_" + match_id,
        )
        # Langflow returns: {"outputs": [{"outputs": [{"results": {"message": {"text": "..."}}]}]}
        try:
            return result["outputs"][0]["outputs"][0]["results"]["message"]["text"].strip()
        except (KeyError, IndexError, TypeError):
            logger.warning("Unexpected Langflow response format: %s", result)
            raise ValueError("Invalid Langflow response")

    async def _generate_via_ollama(self, prompt: str) -> str:
        """Generate summary using Ollama directly."""
        return await self.ollama.generate(
            prompt=prompt,
            system_prompt=TACTICAL_SYSTEM_PROMPT,
            temperature=0.3,
            max_tokens=300,
        )

    async def health_check(self) -> Dict[str, bool]:
        """Check health of both LLM backends."""
        langflow_ok = False
        ollama_ok = False

        if self._use_langflow:
            langflow_ok = await self.langflow.health_check()

        ollama_ok = await self.ollama.health_check()

        return {
            "langflow": langflow_ok,
            "ollama": ollama_ok,
            "primary": "langflow" if self._use_langflow else "ollama",
        }
