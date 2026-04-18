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
import time
from pathlib import Path

from fastapi import FastAPI, HTTPException, Response
from fastapi.responses import FileResponse
from pydantic import BaseModel

ASSETS_DIR = Path(__file__).parent / "assets"

# Artificial delay (seconds) applied to every asset response.
# Override with the ORIGIN_DELAY_MS env var if you want to experiment.
import os
ORIGIN_DELAY_MS = int(os.getenv("ORIGIN_DELAY_MS", "500"))

app = FastAPI(title="CDN Lab Origin", version="0.1.0")


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


@app.get("/assets/{name}")
def get_asset(name: str, response: Response) -> FileResponse:
    """Serve a static asset with an artificial delay + cache headers.

    The ``Cache-Control: public, max-age=30`` header tells any cache (browser,
    CDN, nginx) that this response can be reused for 30 seconds. We keep the
    TTL short so you can watch expiration happen live in the notebook.
    """
    path = ASSETS_DIR / name
    if not path.is_file():
        raise HTTPException(status_code=404, detail=f"no such asset: {name}")

    time.sleep(ORIGIN_DELAY_MS / 1000.0)

    etag = _etag_for(path)
    response.headers["Cache-Control"] = "public, max-age=30"
    response.headers["ETag"] = etag
    response.headers["X-Origin-Server"] = "origin-ny"
    return FileResponse(
        path,
        headers={
            "Cache-Control": "public, max-age=30",
            "ETag": etag,
            "X-Origin-Server": "origin-ny",
        },
    )
