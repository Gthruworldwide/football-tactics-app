# Football data provider engine

## Provider selection

The backend is the only component that owns provider credentials. Never put a
provider key in Flutter, `--dart-define`, a checked-in file, or a log.

For fixtures and standings the backend selects one source for the whole
request:

1. `football-data.org` when `FOOTBALL_DATA_API_KEY` is configured.
2. Highlightly when its key is configured and football-data.org is not.
3. API-Football otherwise.

Responses include `source` and `season` so the client can show provenance.
Provider errors are returned as errors; the engine does not silently substitute
a different season. If football-data.org does not provide scorer data, the
backend may try API-Football only if it returns the exact requested season;
otherwise it returns an explicit error.

## Configure a rotated football-data.org token

Do not paste tokens into chat or source files. Run this from the repository
root; the prompt hides the token and updates the ignored local `.env`:

```powershell
.\backend\.venv\Scripts\python.exe .\backend\scripts\set_football_data_key.py
```

The provider uses season start year `API_FOOTBALL_SEASON` (2026 means
2026/27). If the account plan does not include scorer data, the player tab
returns an explicit provider error instead of invented or old-season values.

## Validate current-season coverage

```powershell
.\backend\.venv\Scripts\python.exe .\backend\scripts\check_football_data_coverage.py
```

The diagnostic prints fixture counts, standings sizes, date ranges, and
provider errors only. It never prints request headers or credentials.

After changing `.env`, restart the backend process so the new provider is
selected. Match and standings caches are provider-specific, preventing data
from an old source from being served after a provider switch.
