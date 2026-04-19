"""
Minimal "webhook vendor" server.

Think of this as the outside service (Stripe, GitHub, SendGrid, ...) that:
  * lets you register a URL with POST /subscriptions
  * POSTs an event payload to every registered URL when POST /trigger is called
  * signs every delivery with an HMAC-SHA256 header so receivers can verify it
  * retries failed deliveries a few times before giving up

Runs on port 5005.
"""

from __future__ import annotations

import asyncio
import hashlib
import hmac
import json
import time
from datetime import datetime
from uuid import uuid4

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, HttpUrl

app = FastAPI()

# In-memory state (this is an educational lab, not production).
SECRET = "super-secret-signing-key"
subscriptions: dict[str, dict] = {}        # id -> {"url": str}
deliveries: list[dict] = []                 # delivery attempts log
MAX_RETRIES = 3
BACKOFF_SECONDS = [0.5, 1.5, 3.0]           # tries: 1st fails → wait 0.5s, ...


class Subscription(BaseModel):
    url: HttpUrl


class Event(BaseModel):
    event: str = "ping"
    data: dict = {}


def sign(body: bytes) -> str:
    """HMAC-SHA256 signature of the raw request body."""
    return hmac.new(SECRET.encode(), body, hashlib.sha256).hexdigest()


async def deliver(sub_id: str, url: str, payload: dict) -> None:
    body = json.dumps(payload).encode()
    signature = sign(body)
    headers = {
        "Content-Type": "application/json",
        "X-Webhook-Signature": f"sha256={signature}",
        "X-Webhook-Event": payload["event"],
        "X-Webhook-Delivery-Id": payload["delivery_id"],
    }

    for attempt in range(1, MAX_RETRIES + 1):
        started = time.time()
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                resp = await client.post(url, content=body, headers=headers)
            ok = 200 <= resp.status_code < 300
            deliveries.append({
                "subscription_id": sub_id,
                "url": url,
                "event": payload["event"],
                "attempt": attempt,
                "status_code": resp.status_code,
                "ok": ok,
                "elapsed_ms": round((time.time() - started) * 1000, 1),
                "at": datetime.now().isoformat(timespec="seconds"),
            })
            print(f"📮 attempt {attempt} → {url} : {resp.status_code}")
            if ok:
                return
        except Exception as exc:  # noqa: BLE001 - log everything in the demo
            deliveries.append({
                "subscription_id": sub_id,
                "url": url,
                "event": payload["event"],
                "attempt": attempt,
                "status_code": None,
                "ok": False,
                "error": str(exc),
                "at": datetime.now().isoformat(timespec="seconds"),
            })
            print(f"📮 attempt {attempt} → {url} : ERROR {exc}")

        if attempt < MAX_RETRIES:
            await asyncio.sleep(BACKOFF_SECONDS[attempt - 1])

    print(f"❌ giving up on {url} after {MAX_RETRIES} attempts")


@app.post("/subscriptions", status_code=201)
def create_subscription(sub: Subscription) -> dict:
    sub_id = uuid4().hex[:8]
    subscriptions[sub_id] = {"url": str(sub.url)}
    print(f"✅ subscription {sub_id} → {sub.url}")
    return {"id": sub_id, "url": str(sub.url)}


@app.delete("/subscriptions/{sub_id}", status_code=204)
def delete_subscription(sub_id: str) -> None:
    if sub_id not in subscriptions:
        raise HTTPException(404, "unknown subscription")
    del subscriptions[sub_id]


@app.get("/subscriptions")
def list_subscriptions() -> dict:
    return {"subscriptions": [{"id": sid, **s} for sid, s in subscriptions.items()]}


@app.post("/trigger")
async def trigger(event: Event) -> dict:
    """Fan out `event` to every registered subscriber."""
    if not subscriptions:
        return {"delivered_to": 0, "note": "no subscribers"}

    tasks = []
    for sub_id, sub in list(subscriptions.items()):
        payload = {
            "event": event.event,
            "data": event.data,
            "delivery_id": uuid4().hex,
            "timestamp": datetime.now().isoformat(timespec="seconds"),
        }
        tasks.append(deliver(sub_id, sub["url"], payload))

    await asyncio.gather(*tasks)
    return {"delivered_to": len(tasks)}


@app.get("/deliveries")
def list_deliveries(limit: int = 20) -> dict:
    return {"deliveries": deliveries[-limit:], "total": len(deliveries)}


@app.get("/secret")
def get_secret() -> dict:
    """Expose the signing secret (demo-only!) so the notebook can verify."""
    return {"secret": SECRET}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Webhook Vendor Server on port 5005")
    uvicorn.run(app, host="0.0.0.0", port=5005, log_level="warning")
