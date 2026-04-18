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
| 2 | Rate Limiting & Auth | Protecting APIs with rate limiting and API key authentication at the gateway |
| 3 | Request Transformation | Header injection, API versioning, and request/response modification |

Each notebook follows the **BAD → BETTER → BEST** pattern so you can see why each concept matters.

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of HTTP (GET, POST, headers, status codes)

## Quick Start

```bash
# Navigate to the lab directory
cd deep-dives/api-gateway

# Start all services (nginx gateway + Flask backends + Redis)
docker-compose up -d --build

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=api-gateway --display-name="API Gateway (Python)"

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
5. **Request/Response Transformation** — modify headers, version APIs

### When to Use an API Gateway
- ✅ Microservices architecture (multiple backend services)
- ✅ Need centralized auth, rate limiting, or logging
- ✅ Multiple client types (web, mobile, IoT)
- ❌ Simple monolithic apps (adds unnecessary complexity)
- ❌ Internal service-to-service calls (use service mesh instead)

## Valid API Keys (for Notebook 2)

| Key | Description |
|-----|-------------|
| `demo-key-123` | Demo/testing key |
| `premium-key-456` | Premium tier key |
| `admin-key-789` | Admin key |

## Cleanup

```bash
# Stop all containers
docker-compose down

# Remove volumes too
docker-compose down -v
```

## License

Educational content — feel free to use and modify for learning purposes.
