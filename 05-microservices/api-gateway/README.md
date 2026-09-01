# API Gateway

📖 **Source**: [Hello Interview – API Gateway Deep Dive](https://www.hellointerview.com/learn/system-design/deep-dives/api-gateway)

## Overview

An API Gateway is the **front desk of your microservices architecture**. Just as hotel guests don't need to know where the housekeeping office is located, clients shouldn't need to know the internal structure of your services.

The gateway provides a **single entry point** for all client requests, handling:
- **Routing** — directing requests to the correct backend service
- **Load Balancing** — distributing traffic across multiple service instances
- **Rate Limiting** — protecting services from abuse
- **Authentication** — validating API keys before requests reach backends
- **Request Transformation** — injecting headers, versioning APIs

This lab uses **nginx** as the API gateway, **two Flask microservices** as backends, and **Redis** for rate limiting demos.

## Architecture

```
                    ┌──────────────────────┐
   Clients ──────▶  │   API Gateway        │
   (port 8080)      │   (nginx)            │
                    └──────┬───────┬───────┘
                           │       │
              ┌────────────┘       └────────────┐
              ▼                                  ▼
   ┌─────────────────────┐           ┌──────────────────┐
   │   User Service       │           │  Order Service    │
   │   (2 instances)      │           │  (1 instance)     │
   │   port 5001, 5003    │           │  port 5002        │
   └─────────────────────┘           └──────────────────┘
              │
              ▼
   ┌─────────────────────┐
   │   Redis              │
   │   (rate limiting)    │
   │   port 6380          │
   └─────────────────────┘
```

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Routing & Load Balancing | Why direct service calls are bad, how path-based routing and load balancing work |
| 2 | Rate Limiting & Auth | Fixed-window vs sliding-window rate limiting (including the 2x burst-at-the-boundary bug), nginx `limit_req`, and API key authentication at the gateway |
| 3 | Request Transformation | Header injection, the gateway as a trust boundary (forgeable headers), API versioning, and request/response modification |
| 4 | Advanced Patterns | Circuit breaker state machine, retry amplification, timeout budgets, request aggregation (BFF) and how it degrades, canary / weighted routing, CORS, observability/logging, SSL termination |

Each notebook follows the **BAD → BETTER → BEST** pattern so you can see why each concept matters.

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of HTTP (GET, POST, headers, status codes)

## Quick Start

```bash
# Navigate to the lab directory
cd 05-microservices/api-gateway

# Start all services (nginx gateway + Flask backends + Redis)
docker compose up -d --build

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5541
- **First time setup**: Click "Add Redis Database" → Host `host.docker.internal`, Port `6380`
- **Use for**: Watch rate limiting counters, see API key lookups

## Service Endpoints

### Through the API Gateway (port 8080) — the RIGHT way
| Endpoint | Description |
|----------|-------------|
| `GET /api/users` | List all users (load balanced) |
| `GET /api/users/1` | Get user by ID |
| `GET /api/orders` | List all orders |
| `GET /api/orders/101` | Get order by ID |
| `GET /api/auth/users` | List users (requires `X-API-Key` header) |
| `GET /api/v2/users` | List users (API version 2 format) |
| `GET /api/debug/headers` | See what headers the backend receives |
| `GET /health` | Gateway health check |
| `GET /api/profile/:id` | Aggregated user profile + orders (BFF pattern) |
| `GET /api/canary/users` | Weighted canary routing (~90% stable / ~10% canary) |
| `GET /api/cors/users` | CORS-enabled endpoint (preflight + real request) |

### Direct service access (exposed ports) — the BAD way (for learning only)
| Endpoint | Description |
|----------|-------------|
| `localhost:5001/users` | User Service instance 1 |
| `localhost:5003/users` | User Service instance 2 |
| `localhost:5002/orders` | Order Service |

## Key Concepts Covered

### Why API Gateways Exist
- **Single entry point** — clients only need one URL
- **Decoupling** — backend services can change without affecting clients
- **Cross-cutting concerns** — auth, rate limiting, logging in one place

### Core Responsibilities
1. **Request Routing** — map URL paths to backend services
2. **Load Balancing** — distribute traffic across service instances
3. **Rate Limiting** — prevent abuse and protect backends
4. **Authentication** — validate credentials before forwarding
5. **Request/Response Transformation** — modify headers, version APIs; **clear or overwrite** every header the backend trusts, or the client can forge it
6. **Resilience** — circuit-breaker-style failover (`max_fails`/`fail_timeout`), bounded retries, and a timeout budget that shrinks with depth
7. **Request Aggregation** — BFF pattern combining multiple backend calls
8. **Canary / Weighted Routing** — gradual rollouts via weighted upstream servers
9. **CORS** — cross-origin request handling at the gateway
10. **Observability** — structured access logs with request IDs and upstream timing
11. **SSL Termination** — TLS offloading at the gateway (concept-only in this lab)

### When to Use an API Gateway
- ✅ Microservices architecture (multiple backend services)
- ✅ Need centralized auth, rate limiting, or logging
- ✅ Multiple client types (web, mobile, IoT)
- ❌ Simple monolithic apps (adds unnecessary complexity)
- ❌ Internal service-to-service calls (use service mesh instead)

## What This Lab Does NOT Do

Honest scope, so you don't carry the wrong lesson into a design:

- **Auth is API keys in an nginx `map`, not JWT/OAuth.** No signature verification, no expiry, no revocation without a config reload. Real gateways validate a signed token (and pin the algorithm — accepting `alg: none` or skipping signature verification is a classic critical bug).
- **No active health checks.** nginx OSS never calls `/health` on its own; it only ejects a backend *after* real requests to it fail (`max_fails`/`fail_timeout`). Active probing needs nginx Plus, Envoy, or a service mesh.
- **No true circuit breaker at the gateway.** Notebook 4 simulates the open/half-open/closed state machine in Python because nginx OSS has no such thing.
- **`worker_processes 1`** is set deliberately so the load-balancing demos are exactly reproducible. Production uses `worker_processes auto` plus a shared-memory `zone` in the upstream.
- **Aggregation lives inside `user_service.py`**, not in a dedicated BFF, to keep the container count low. Notebook 4 says why that's the wrong shape at scale.
- **TLS termination is concept-only** — the lab ships no certificates.

## Valid API Keys (for Notebook 2)

| Key | Description |
|-----|-------------|
| `demo-key-123` | Demo/testing key |
| `premium-key-456` | Premium tier key |
| `admin-key-789` | Admin key |

## Cleanup

```bash
# Stop all containers
docker compose down

# Remove volumes too
docker compose down -v
```

## License

Educational content — feel free to use and modify for learning purposes.
