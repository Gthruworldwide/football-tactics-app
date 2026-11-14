# External Repository Integration Plan

This document records how the seven referenced repositories fit the Football
Tactics Analytics app. Catalog repositories are used as references; they are
not runtime dependencies.

## 1. API discovery

**Repository:** `public-apis/public-apis`

Use only for evaluating free data providers. The production app should keep
API keys on the backend and expose one normalized API to Flutter.

Current decision:

- API-Football remains the primary fixture provider.
- Understat/Scrapling remains the tactical-history provider.
- New providers require a backend adapter and tests before activation.

## 2. MCP ecosystem

**Repository:** `punkpeye/awesome-mcp-servers`

Use it as a directory for optional MCP integrations. The current app has a
dedicated MCP service with `/health` and `/v1/tactical/summary`; new tools
must be allow-listed and must not expose secrets or arbitrary shell access.

## 3. Design system

**Repository:** `nexu-io/open-design`

Use as a design reference only. The Flutter app already has centralized theme
tokens in `frontend/lib/core/theme/` and should continue using those tokens
instead of copying generated page-specific styles.

## 4. LLM application patterns

**Repository:** `Shubhamsaboo/awesome-llm-apps`

Applicable patterns:

- structured tactical prompts;
- provider fallback;
- health checks;
- explicit model configuration;
- no-news system prompt.

These are implemented in `mcp_server/tactical_summary.py`,
`mcp_server/ollama_client.py`, and `mcp_server/langflow_client.py`.

## 5. General engineering references

**Repository:** `sindresorhus/awesome`

Reference only. No runtime dependency is required.

## 6. Scraping

**Repository:** `D4Vinci/Scrapling`

Current integration:

- `backend/scripts/scrape_understat.py` stores xG and player data in SQLite.
- `backend/app/services/scrapling_pipeline.py` is the service boundary.

Scraped data must be cached, rate-limited, validated, and never used to
collect news or articles.

## 7. Free-service and local-runtime references

**Repositories:** `ripienaar/free-for-dev`, `ollama/ollama`

Current decisions:

- Ollama is the local LLM fallback.
- External free services are optional adapters, not hard dependencies.
- API quotas and provider failures are handled by backend fallback logic.

## 8. OpenHands

**Repository:** `All-Hands-AI/OpenHands`

OpenHands is a development automation tool, not an application runtime
dependency. It should be used externally for issue-driven coding and review,
with repository permissions restricted and secrets excluded.

## Security rules

- Never commit `.env`, API keys, tokens, or generated APK signing material.
- Never expose provider keys in Flutter source.
- Never enable arbitrary MCP tools in production.
- Keep the no-news/no-articles product rule enforced.
- Validate all external API responses with typed schemas.
