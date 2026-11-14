"""Check player endpoints without printing player data or credentials."""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.config import settings
from app.services.highlightly import HighlightlyService


async def main() -> None:
    if not settings.HIGHLIGHTLY_API_KEY:
        raise SystemExit("HIGHLIGHTLY_API_KEY is not configured.")

    async with HighlightlyService() as api:
        response = await api._get("/players", {"limit": 1, "offset": 0})
        rows = response.get("data", []) if isinstance(response, dict) else []
        pagination = response.get("pagination", {}) if isinstance(response, dict) else {}
        plan = response.get("plan", {}) if isinstance(response, dict) else {}
        print(
            f"Player index: {len(rows)} returned; "
            f"total={pagination.get('totalCount', 'n/a')}; "
            f"plan={plan.get('tier', 'n/a')}"
        )
        if rows and isinstance(rows[0].get("id"), int):
            stats = await api._get(
                f"/players/{rows[0]['id']}/statistics", {}
            )
            records = stats.get("perCompetition", []) if isinstance(stats, dict) else []
            print(
                f"First indexed player's statistics endpoint: "
                f"{len(records)} competition records"
            )


if __name__ == "__main__":
    asyncio.run(main())
