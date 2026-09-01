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

# 3 attempts = 1 try + 2 retries, so we need 2 gaps. Doubling each time is
# "exponential backoff"; production adds random jitter on top so that a fleet
# of receivers coming back after an outage doesn't retry in lockstep. We keep
# it jitter-free here purely so the notebook's timings are reproducible.
MAX_ATTEMPTS = 3
BACKOFF_SECONDS = [0.5, 1.0]                # wait after attempt 1, after attempt 2


class Subscription(BaseModel):
    url: HttpUrl


class Event(BaseModel):
    event: str = "ping"
    data: dict = {}


def sign(timestamp: int, body: bytes) -> str:
    """HMAC-SHA256 over `<timestamp>.<raw body>` -- the Stripe scheme.

    Signing the body alone is not enough: an attacker who captures one valid
    delivery could replay it verbatim forever, and the signature would still
    check out. Binding a timestamp into the signed string lets the receiver
    reject anything older than a few minutes.
    """
    signed_payload = str(timestamp).encode() + b"." + body
    return hmac.new(SECRET.encode(), signed_payload, hashlib.sha256).hexdigest()


async def deliver(sub_id: str, url: str, payload: dict) -> None:
    body = json.dumps(payload).encode()
    # Signed once, outside the retry loop: every retry re-sends the *identical*
    # bytes, headers and delivery id. That is what makes the receiver able to
    # dedupe on `X-Webhook-Delivery-Id`.
    timestamp = int(time.time())
    signature = sign(timestamp, body)
    headers = {
        "Content-Type": "application/json",
        "X-Webhook-Signature": f"sha256={signature}",
        "X-Webhook-Timestamp": str(timestamp),
        "X-Webhook-Event": payload["event"],
        "X-Webhook-Delivery-Id": payload["delivery_id"],
    }

    for attempt in range(1, MAX_ATTEMPTS + 1):
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
                "delivery_id": payload["delivery_id"],
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
                "delivery_id": payload["delivery_id"],
                "status_code": None,
                "ok": False,
                "error": str(exc),
                "at": datetime.now().isoformat(timespec="seconds"),
            })
            print(f"📮 attempt {attempt} → {url} : ERROR {exc}")

        if attempt < MAX_ATTEMPTS:
            await asyncio.sleep(BACKOFF_SECONDS[attempt - 1])

    print(f"❌ giving up on {url} after {MAX_ATTEMPTS} attempts")


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

    # A real vendor enqueues the deliveries and returns immediately -- it will
    # not hold your API call open for the length of a retry schedule. We await
    # here so the notebook can observe the whole attempt sequence in one cell.
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
