"""Back up the local analytics database and remove the known test-fixture rows."""

from __future__ import annotations

import sqlite3
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATABASE = ROOT / "backend" / "data" / "tactics_analytics.db"
BACKUP_DIR = Path.home() / "Documents" / "Codex" / "database-backups"

PLAYER_MATCH = (
    "league = 'EPL' AND season = 2026 AND player_name = 'A' "
    "AND team_name = 'T' AND games = 0 AND goals = 0 AND xg = 5.5"
)
STANDING_MATCH = (
    "league = 'EPL' AND season = 2026 AND rank = 1 "
    "AND team_name = 'T' AND points = 9"
)


def main() -> None:
    if not DATABASE.is_file():
        raise SystemExit(f"Database does not exist: {DATABASE}")

    with sqlite3.connect(DATABASE) as source:
        player_count = source.execute(
            f"SELECT COUNT(*) FROM players WHERE {PLAYER_MATCH}"
        ).fetchone()[0]
        standing_count = source.execute(
            f"SELECT COUNT(*) FROM standings WHERE {STANDING_MATCH}"
        ).fetchone()[0]

        if not player_count and not standing_count:
            print("No matching demo rows found; database left unchanged.")
            return

        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        backup_path = BACKUP_DIR / (
            f"tactics_analytics_before_demo_cleanup_"
            f"{datetime.now():%Y%m%d_%H%M%S}.db"
        )
        with sqlite3.connect(backup_path) as backup:
            source.backup(backup)

        source.execute("BEGIN IMMEDIATE")
        deleted_players = source.execute(
            f"DELETE FROM players WHERE {PLAYER_MATCH}"
        ).rowcount
        deleted_standings = source.execute(
            f"DELETE FROM standings WHERE {STANDING_MATCH}"
        ).rowcount
        source.commit()

    print(
        f"Removed {deleted_players} known demo player row(s) and "
        f"{deleted_standings} known demo standing row(s)."
    )
    print(f"Pre-cleanup database backup: {backup_path}")


if __name__ == "__main__":
    main()
