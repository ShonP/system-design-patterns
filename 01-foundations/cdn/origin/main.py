"""Tiny FastAPI "origin" server for the CDN lab.

Think of this as a single web server in one data center (say, New York).
Every response is intentionally slowed down so you can *see* the effect of
caching at the edge. In the real world, the slowness would come from:

- The server being far from the user (network latency)
- The server being busy (CPU/DB load)
- The file being big

We simulate all of that with a simple ``time.sleep``.
"""
from __future__ import annotations

import hashlib
import os
import time
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import FileResponse
from pydantic import BaseModel

ASSETS_DIR = Path(__file__).parent / "assets"

# Artificial delay (seconds) applied to every full asset response.
# Override with the ORIGIN_DELAY_MS env var if you want to experiment.
ORIGIN_DELAY_MS = int(os.getenv("ORIGIN_DELAY_MS", "500"))

app = FastAPI(title="CDN Lab Origin", version="0.2.0")


class HealthResponse(BaseModel):
    status: str
    delay_ms: int


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """Fast, uncached health check — used by docker-compose healthcheck."""
    return HealthResponse(status="ok", delay_ms=ORIGIN_DELAY_MS)


@app.get("/")
def root() -> dict:
    return {
        "service": "origin",
        "message": "I am the slow origin server. Edges should cache me!",
        "assets": [p.name for p in ASSETS_DIR.iterdir() if p.is_file()],
    }


def _etag_for(path: Path) -> str:
    """Cheap ETag = md5 of file bytes. Good enough for teaching."""
    return hashlib.md5(path.read_bytes()).hexdigest()


def _matches_inm(if_none_match: str | None, etag: str) -> bool:
    """Return True if the client's If-None-Match header matches our etag.

    Browsers and caches send the ETag back wrapped in quotes, sometimes with
    a ``W/`` weak-validator prefix, and may send a comma-separated list. We
    accept any of them and the bare md5 too (which is what curl + the
    notebooks use).
    """
    if not if_none_match:
        return False
    for token in if_none_match.split(","):
        token = token.strip()
        if token.startswith("W/"):
            token = token[2:].strip()
        token = token.strip('"')
        if token == etag or token == "*":
            return True
    return False


@app.get("/assets/{name}")
def get_asset(name: str, request: Request) -> Response:
    """Serve a static asset with an artificial delay + cache headers.

    The ``Cache-Control: public, max-age=30`` header tells any cache (browser,
    CDN, nginx) that this response can be reused for 30 seconds. We keep the
    TTL short so you can watch expiration happen live in the notebook.

    If the client sends ``If-None-Match`` and it matches our current ETag,
    we return ``304 Not Modified`` with an empty body — and we **skip** the
    artificial 500 ms delay, because in the real world a 304 check is just
    an ETag comparison, not a full render.
    """
    path = ASSETS_DIR / name
    if not path.is_file():
        raise HTTPException(status_code=404, detail=f"no such asset: {name}")

    etag = _etag_for(path)
    cache_headers = {
        "Cache-Control": "public, max-age=30",
        "ETag": etag,
        "X-Origin-Server": "origin-ny",
    }

    # Conditional request: client already has this version → 304, no body, no sleep.
    if _matches_inm(request.headers.get("if-none-match"), etag):
        return Response(status_code=304, headers=cache_headers)

    # Full response: pay the artificial "I am a slow origin" cost.
    time.sleep(ORIGIN_DELAY_MS / 1000.0)
    return FileResponse(path, headers=cache_headers)

