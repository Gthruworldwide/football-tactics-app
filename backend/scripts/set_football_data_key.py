"""Save a newly rotated football-data.org key to ignored local .env."""

from getpass import getpass
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    env_path = root / ".env"
    token = getpass("Paste the newly rotated football-data.org token (hidden): ").strip()
    if not token or "\n" in token or "\r" in token:
        raise SystemExit("A valid single-line token is required.")

    lines = env_path.read_text(encoding="utf-8").splitlines() if env_path.exists() else []
    key_line = f"FOOTBALL_DATA_API_KEY={token}"
    for index, line in enumerate(lines):
        if line.lstrip().startswith("FOOTBALL_DATA_API_KEY="):
            lines[index] = key_line
            break
    else:
        lines.append(key_line)

    env_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    print("Saved to the ignored local .env file. The token was not displayed.")


if __name__ == "__main__":
    main()
