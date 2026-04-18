# API Design

📖 **Source**: [Hello Interview – API Design for System Design Interviews](https://www.hellointerview.com/learn/system-design/core-concepts/api-design)

## Overview

API design is how clients interact with your system. Good API design follows predictable patterns: you pick a protocol, define your resources, and specify how clients pass data and get responses back.

This lab focuses on **REST APIs** — the default choice for most web services. You'll build and interact with a real event-ticketing API to learn resource modeling, HTTP methods, pagination, rate limiting, and versioning — all with runnable code.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | REST API Design Principles | Resource modeling, HTTP methods, path vs query params, status codes |
| 2 | Pagination Strategies | Offset-based vs cursor-based pagination, trade-offs |
| 3 | Rate Limiting Basics | Fixed-window rate limiting, 429 responses, rate-limit headers |
| 4 | API Versioning | URL versioning (v1 vs v2), backward compatibility, migration |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of HTTP

## Quick Start

```bash
# Navigate to the lab directory
cd core-concepts/api-design

# Start PostgreSQL + FastAPI server + Adminer
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=api-design --display-name="API Design (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `api_design_demo`
- **Use for**: Browse events, bookings, venues — see what the API reads and writes

### FastAPI Docs (auto-generated)
- **URL**: http://localhost:8000/docs
- **Use for**: Interactive Swagger UI — try every endpoint right in the browser

## Architecture

```
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│   Notebook   │──HTTP──▶│  FastAPI      │──SQL──▶│  PostgreSQL  │
│  (requests)  │◀───────│  Server :8000 │◀──────│    :5432     │
└──────────────┘        └──────────────┘        └──────────────┘
                                                        │
                                                ┌───────┴──────┐
                                                │   Adminer    │
                                                │   :8080      │
                                                └──────────────┘
```

## Key Concepts Covered

### REST Design Principles
- **Resources are nouns** — `/events`, `/bookings`, not `/getEvents`
- **HTTP methods are verbs** — GET reads, POST creates, PUT replaces, PATCH updates, DELETE removes
- **Path params for identity** — `/events/123` (required)
- **Query params for filters** — `/events?category=music` (optional)

### Pagination
- **Offset-based** — simple, supports "jump to page N", but unstable with inserts
- **Cursor-based** — stable, efficient for large datasets, but no random page access

### Rate Limiting
- Protects your API from abuse and overload
- Fixed-window algorithm (simplest approach)
- Standard `Retry-After` header (RFC 6585) plus vendor `X-RateLimit-*` headers
- Per-client quotas via `X-API-Key` (so shared IPs don't get collectively punished)

### API Versioning
- **URL versioning** (`/v1/events` vs `/v2/events`) — explicit and easy to understand
- Backward compatibility — old clients keep working on v1
- Standard `Deprecation` / `Sunset` / `Link: rel="successor-version"` response headers
- Migration path — gradual rollout of breaking changes

## Real-World Examples

| System | API Design Choice | Why |
|--------|-------------------|-----|
| Stripe | URL versioning (`/v1/`) | Public API, can't break existing integrations |
| GitHub | REST + cursor pagination | Millions of repos, stable pagination needed |
| Twitter | Rate limiting per endpoint | Prevent scraping, ensure fair access |
| Ticketmaster | Nested resources | Events → Tickets → Bookings hierarchy |

## License

Educational content — feel free to use and modify for learning purposes.
