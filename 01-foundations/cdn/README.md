# Content Delivery Networks (CDN)

📖 **Source**: [Grokking System Design Fundamentals — CDN lessons](https://www.designgurus.io/course-play/grokking-system-design-fundamentals)
(scraped copies live in [`references/designgurus.md`](./references/designgurus.md))

## Overview

A **CDN (Content Delivery Network)** is a fleet of servers spread around the
world that keep copies of your content close to your users. Instead of every
user reaching your single origin server, they reach a nearby **edge** server
that already has a cached copy.

This lab teaches the mental model hands-on. You'll run:

- a **slow FastAPI origin** (500 ms artificial delay per asset),
- **two nginx edge caches** (ports 8081 and 8082, simulating two PoPs),

and watch `MISS → HIT`, push-vs-pull, TTL expiration, and cache purging
happen live — with real HTTP headers and real latency numbers.

## Learning objectives

- Explain **origin** vs **edge** and measure the latency gap between them.
- Compare **pull** and **push** CDN models and pick one for a workload.
- Read `Cache-Control`, `ETag`, and `X-Cache-Status` headers to predict and
  debug caching behaviour.

## Notebooks in this series

| # | Notebook | What you'll learn |
|---|----------|-------------------|
| 1 | [`notebooks/01_what_is_a_cdn.ipynb`](./notebooks/01_what_is_a_cdn.ipynb) | Origin vs edge vs client; bad/better/best scaling; `MISS` → `HIT` |
| 2 | [`notebooks/02_push_vs_pull_cdn.ipynb`](./notebooks/02_push_vs_pull_cdn.ipynb) | Pull CDN (lazy fetch) vs Push CDN (pre-uploaded); when to choose each |
| 3 | [`notebooks/03_cache_headers_and_invalidation.ipynb`](./notebooks/03_cache_headers_and_invalidation.ipynb) | `Cache-Control`, `ETag`, TTL, stale content, versioned URLs, cache purging |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- [`uv`](https://docs.astral.sh/uv/) for Python dependency management

## Quick start

```bash
# From this directory (01-foundations/cdn)

# 1. Start origin + edge1 + edge2
docker compose up -d --build

# 2. Install Python deps into a local .venv
uv sync

# 3. Open any notebook in VS Code and select the .venv kernel
#    (top-right kernel picker). If the kernel isn't listed,
#    Cmd+Shift+P → "Reload Window" and try again.
```

### URLs you can poke from your browser or curl

| Service | URL                          | What it is |
|---------|------------------------------|------------|
| origin  | http://localhost:8000/       | FastAPI app, 500 ms delay per asset |
| origin  | http://localhost:8000/assets/hello.txt | Sample asset |
| edge1   | http://localhost:8081/assets/hello.txt | First nginx edge (PoP 1) |
| edge2   | http://localhost:8082/assets/hello.txt | Second nginx edge (PoP 2) |
| edge1   | http://localhost:8081/pushed/ | Push-CDN drop-zone for edge1 |

Useful headers to watch on edge responses:

- `X-Cache-Status: MISS | HIT | EXPIRED | PUSHED` — did the edge need the origin?
- `X-Edge-Server: edge1 | edge2` — which PoP answered you?
- `Cache-Control`, `ETag`, `Age` — the standard HTTP cache contract.

## Architecture

```
                    ┌────────────────┐
                    │   FastAPI      │   (slow: 500 ms/request)
                    │    origin      │
                    │  :8000         │
                    └───────▲────────┘
                            │
              proxy_cache MISS fetches
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
   ┌──────┴──────┐                     ┌──────┴──────┐
   │  nginx      │                     │  nginx      │
   │  edge1      │                     │  edge2      │
   │  :8081      │                     │  :8082      │
   └──────▲──────┘                     └──────▲──────┘
          │                                   │
      users near PoP 1                    users near PoP 2
```

## Key concepts covered

- **Origin** — primary source of truth (one server, far away, maybe slow).
- **Edge / PoP** — cached copy close to users.
- **Pull CDN** — edge fetches on first miss (Cloudflare, Fastly, CloudFront default).
- **Push CDN** — content owner pre-uploads assets to edges (Akamai NetStorage).
- **TTL** (`Cache-Control: max-age`) — how long a cached copy may be reused.
- **ETag** + `If-None-Match` — conditional revalidation (`304 Not Modified`).
- **Cache invalidation** — purge or versioned URLs to defeat stale content.

## Tearing down

```bash
docker compose down -v   # -v also removes the edge cache volumes
```

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping

## License

Educational content — feel free to use and modify for learning purposes.
