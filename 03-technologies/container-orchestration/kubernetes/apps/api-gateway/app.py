"""API Gateway — routes requests to user-service and order-service."""

from __future__ import annotations

import os

import httpx
from fastapi import FastAPI, HTTPException

app = FastAPI(title="API Gateway", version="1.0.0")

USER_SERVICE = os.getenv("USER_SERVICE_URL", "http://user-service:8001")
ORDER_SERVICE = os.getenv("ORDER_SERVICE_URL", "http://order-service:8002")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "api-gateway"}


@app.get("/api/users")
async def list_users() -> dict[str, object]:
    async with httpx.AsyncClient(timeout=5) as client:
        try:
            resp = await client.get(f"{USER_SERVICE}/users")
            return resp.json()
        except httpx.RequestError as e:
            raise HTTPException(502, f"user-service unreachable: {e}")


@app.get("/api/orders")
async def list_orders() -> dict[str, object]:
    async with httpx.AsyncClient(timeout=5) as client:
        try:
            resp = await client.get(f"{ORDER_SERVICE}/orders")
            return resp.json()
        except httpx.RequestError as e:
            raise HTTPException(502, f"order-service unreachable: {e}")


@app.get("/api/status")
async def cluster_status() -> dict[str, object]:
    results: dict[str, str] = {}
    async with httpx.AsyncClient(timeout=3) as client:
        for name, url in [("users", USER_SERVICE), ("orders", ORDER_SERVICE)]:
            try:
                resp = await client.get(f"{url}/health")
                results[name] = "healthy" if resp.status_code == 200 else "degraded"
            except httpx.RequestError:
                results[name] = "unreachable"
    return {"gateway": "healthy", "backends": results}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
