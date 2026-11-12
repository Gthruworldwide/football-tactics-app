# Football Tactics Analytics Engine

## Overview

A minimalist Single Page Application (SPA) for football analysts, commentators, and tacticians. Built with a strict no-news policy and focused solely on tactical analytics.

## Core Features

- **5-Country Geographic Filter**: England (Premier League), Spain (La Liga), Italy (Serie A) + auto-detected Geo-IP country + user-selectable country
- **Live Match Data**: Live scores, live minute, channel name, commentator name
- **Tactical Analytics**: xG, xA, PPDA, Field Tilt, Momentum graphs
- **AI Commentator Summaries**: Generated via Langflow + Ollama MCP
- **Minimalist UI**: Horizontal date bar + calendar picker, league filter chips, match cards

## Technology Stack

### Backend
- **Framework**: Python 3.11 + FastAPI (Async)
- **API Engine**: API-Football (Live scores, lineups, player ratings)
- **Secondary Engine**: Football-Data.org v4 (Fixtures & fallback standings)
- **Stealth Scraper**: Scrapling framework for xG, xA, PPDA from Understat
- **Geo-IP**: IPinfo Lite API (Country detection)
- **Caching**: Redis (TTL: 15s live, 24h static)
- **AI Architecture**: Langflow + Ollama MCP

### Frontend
- **Framework**: Flutter (Web/Mobile SPA) with RTL support
- **State Management**: Flutter BLoC Pattern
- **Local Storage**: Hive / Hydrated BLoC

## Project Structure

```
football-tactics-app/
├── backend/
│   ├── app/
│   │   ├── api/v1/endpoints/    ← API endpoints
│   │   ├── core/                ← Config, database, constants
│   │   ├── services/            ← API-Football, scrapping, AI
│   │   └── main.py              ← FastAPI entry point
│   ├── Dockerfile               ← Container configuration
│   └── requirements.txt         ← Python dependencies
├── frontend/
│   ├── lib/
│   │   ├── core/                ← Constants, themes
│   │   ├── data/                └── Hive local cache
│   │   ├── logic/               └── BLoC architecture
│   │   │   ├── matches_bloc.dart
│   │   │   ├── country_bloc.dart
│   │   │   └── tactical_bloc.dart
│   │   └── presentation/        └── UI widgets
│   │       ├── match_card.dart
│   │       ├── date_bar.dart
│   │       └── league_filter_chips.dart
│   └── pubspec.yaml             ← Flutter dependencies
├── mcp_server/
│   └── server.py                ← MCP server entry point
└── README.md                    ← This file
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