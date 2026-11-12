Master Project Blueprint: Tactical & Minimalist Football Analytics Engine (SPA)
1. Project Overview & Product Vision
Build a highly specialized, minimalist, zero-bloat Football Analytics Application designed specifically for football analysts, commentators, and hardcore tacticians.

Core Product Constraints:
STRICTLY NO NEWS / NO ARTICLES: Absolute exclusion of transfer news, gossip, or opinion pieces.

Single Page Application (SPA) Design: Ultra-fast, single-screen layout based on a minimal design system.

5-Country Strict Geographic Filter:

3 Permanent Core Countries (Non-removable): England (Premier League, FA Cup, EFL Cup), Spain (La Liga, Copa del Rey), Italy (Serie A, Coppa Italia).

1 Dynamic Geo-IP Country: Automatically detected upon launch via IPinfo Lite API (e.g., Egypt -> Egyptian Premier League, Egypt Cup, League Cup).

1 User-Selectable Country: Custom choice by user (e.g., Netherlands -> Eredivisie, KNVB Beker).

Key Match Card Data Points: Match Time (Local Timezone), Channel Name, Commentator Name, Live Scores, Live Minute, and Tactical Stats.

Tactical & AI Analytics: Real-time xG, xA, PPDA (Passes Per Defensive Action), Field Tilt, Momentum Graphs, and AI-generated Tactical Summaries for TV Commentators.

2. Directory Structure Setup
football-tactics-app/
├── backend/
│   ├── app/
│   │   ├── api/v1/endpoints/
│   │   ├── core/
│   │   ├── services/
│   │   └── main.py
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/
│   ├── lib/
│   │   ├── core/
│   │   ├── data/
│   │   ├── logic/
│   │   └── presentation/
│   └── pubspec.yaml
├── mcp_server/
│   └── server.py
└── README.md

3. Technology Stack & External Services
Backend:
Framework: Python 3.11 + FastAPI (Async).

Primary API Engine: API-Football (Live scores, lineups, player ratings 0-10, events).

Secondary API Engine: Football-Data.org v4 (Fixtures & fallback standings).

Stealth Web Scraper: Scrapling framework for extracting xG, xA, and PPDA metrics from Understat/advanced sources.

Geo-IP Provider: IPinfo Lite API (Country detection).

Caching Layer: Redis (TTL: 15s live, 24h static).

AI Agent Architecture: Langflow + Ollama (IBM Granite / Llama models) running via Model Context Protocol (MCP).

Frontend:
Framework: Flutter (Web/Mobile SPA) with RTL support.

State Management: Flutter BLoC Pattern.

Local Storage: Hive / Hydrated BLoC.

4. System Prompt for OpenCode Execution
YOU ARE ACTING AS A PRINCIPAL FULL-STACK ARCHITECT AND SENIOR FLUTTER/FASTAPI DEVELOPER.
YOUR TASK IS TO IMPLEMENT THE FOOTBALL ANALYTICS APPLICATION DESCRIBED IN THIS BLUEPRINT.

STRICT RULES:

DO NOT GENERATE ANY NEWS OR ARTICLES CODE.

IMPLEMENT THE 5-COUNTRY GEOGRAPHIC RESTRICTION STRICTLY (England, Spain, Italy + Geo-IP Country + 1 Optional Choice).

BUILD A SINGLE PAGE APPLICATION (SPA) WITH A MINIMALIST UI:

Horizontal Date Bar + Embedded Calendar Picker at top.

League filter chips (5 countries only).

Match Cards displaying: Time (Local), Teams, Live Minute, Channel Name, Commentator Name.

Tactical Modal/Drawer: xG, PPDA, Field Tilt Graph, and AI Commentator Summary.

BACKEND SETUP:

FastAPI with Redis caching.

API-Football integration.

Scrapling stealth scraping layer.

Langflow + Ollama MCP Server.

FRONTEND SETUP:

Flutter SPA with BLoC architecture and Hive local cache.

START BY GENERATING THE BACKEND FASTAPI CORE STRUCTURE, SCRAPLING PIPELINE, REDIS CACHE, AND FLUTTER BLOC LAYERS.