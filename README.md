# Wasl (وصل) — Independent Connected Knowledge App

## Overview

Wasl is a clean, standalone Flutter mobile app for building a source-backed knowledge graph about any topic. It lives in `wasl/`, has its own Android application ID (`com.gthruworldwide.wasl_app`), and starts with an empty on-device store. It does not import data, screens, services, or dependencies from the existing football app in `frontend/`.

## Core Features

- **General-purpose entities**: Add people, organizations, websites, places, events, and any other entity type.
- **Cited facts and connections**: Each entry requires an HTTP(S) source URL; valid-time ranges are optional and separate from retrieval time.
- **Safe identity handling**: Each entity gets a unique local ID. Matching names never merge records.
- **Private by default**: Wasl uses its own app storage and has no backend connection, account sync, or imported football data.

## Wasl mobile app

All Wasl records are entered by the user and stored locally on the device. Source URLs are user-supplied and are not independently verified. Local preferences are not encrypted by Wasl and do not sync across devices. AI explanations are deferred; displayed facts and relationships show their sources.

```powershell
cd wasl
flutter run
flutter test
flutter build apk --release
```

## Technology Stack

### Backend
- **Framework**: Python 3.11 + FastAPI (Async)
- **API Engine**: API-Football (Live scores, lineups, player ratings)
- **Secondary Engine**: Football-Data.org v4 (Fixtures & fallback standings)
- **Stealth Scraper**: Scrapling framework for xG, xA, PPDA from Understat
- **Geo-IP**: IPinfo Lite API (Country detection)
- **Caching**: Redis (TTL: 15s live, 24h static)
- **AI Architecture**: Langflow + Ollama MCP

### Apps
- **Wasl (`wasl/`)**: Independent Flutter Android/iOS app; generic knowledge graph and local-only storage.
- **Existing football app (`frontend/`)**: Separate legacy Flutter app with its own screens, dependencies, and backend integrations.

## Project Structure

```
football-tactics-app/
├── backend/
│   ├── app/
│   │   ├── api/            ← v1.py (matches/standings), tactics.py (read DB), sync.py
│   │   ├── core/           ← config, database (SQLite schema), redis_client
│   │   ├── services/       ← api_football, tactical_metrics, ai_summary, geolocation
│   │   └── main.py         ← FastAPI entry point
│   ├── scripts/            ← scrape_understat.py, sqlite_mcp.py (run from backend/)
│   ├── tests/
│   ├── data/               ← SQLite DB lives here (git-ignored)
│   ├── Dockerfile
│   └── requirements*.txt
├── frontend/               ← Flutter app (BLoC)
├── wasl/                   ← Independent general-knowledge Flutter app
├── mcp_server/             ← AI summary MCP server (own Dockerfile)
├── docker-compose.yml
└── .env.example
```

## Run

```bash
cp .env.example .env          # fill in keys
docker compose up --build     # backend :8000, mcp :8001
cd backend && python -m pytest -q
cd backend && python -m scripts.scrape_understat   # fill the xG database (needs requirements-scrapers.txt)
```

## Implementation Status

### Backend ✅
- [x] FastAPI application structure
- [x] Redis caching with TTL configuration (15s live, 24h static)
- [x] API-Football integration service
- [x] Scrapling pipeline for tactical metrics (xG, xA, PPDA)
- [x] Geo-IP country detection
- [x] 5-country strict geographic filter
- [x] AI tactical summary service (Langflow + Ollama MCP)
- [x] Docker configuration

### Frontend ✅
- [x] Flutter project creation
- [x] BLoC state management architecture
- [x] Hive local storage with HydratedBloc
- [x] Minimalist UI theme (light/dark)
- [x] Horizontal date bar with calendar picker
- [x] League filter chips (5 countries)
- [x] Match card widget with team info, live minute, channel, commentator
- [x] Tactical stats display (xG, xA, PPDA, field tilt, momentum)
- [x] AI commentator summary generation

### System Prompt ✅
- [x] Acting as principal full-stack architect
- [x] Senior Flutter/FastAPI developer role
- [x] Strict no-news rule enforced
- [x] 5-country geographic restriction implemented

## Running the Application

### Backend
```bash
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Frontend
```bash
cd frontend
flutter run
```

### MCP Server
```bash
cd mcp_server
python server.py
```

## Compliance with Blueprint Constraints

- [x] **STRICTLY NO NEWS/ARTICLES**: No news or article code generated
- [x] **5-COUNTRY GEOGRAPHIC RESTRICTION**: England, Spain, Italy + Geo-IP + User choice
- [x] **SPA WITH MINIMALIST UI**: Horizontal date bar, filter chips, match cards
- [x] **Tactical Analytics**: xG, xA, PPDA, Field Tilt, Momentum, AI summaries
- [x] **Single Page Application**: All content on one screen
## Flutter API keys

Keys are no longer in the source. Copy `frontend/dart_defines.example.json` to `frontend/dart_defines.json`, fill it in, then:

```bash
cd frontend
flutter run --dart-define-from-file=dart_defines.json
flutter build apk --release --dart-define-from-file=dart_defines.json
```

For CI, add `API_SPORTS_KEY`, `RAPIDAPI_KEY`, `APILAYER_KEY` as GitHub repository secrets.
