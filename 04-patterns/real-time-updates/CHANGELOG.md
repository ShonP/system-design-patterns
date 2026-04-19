# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19 (evening QA pass)
- **Re-verified** all 8 notebooks execute end-to-end against the five
  `servers/*.py` processes + existing Redis — 0 errors.
- **New content — Notebook 05 "🔐 Authentication & Authorization":**
  covers the four real patterns (query-string token, token-in-first-message,
  `Sec-WebSocket-Protocol` subprotocol, cookies) with a runnable demo
  against the lab's existing server showing both an accepted and a
  rejected client. Closes the biggest beginner gap in the WebSocket
  lesson — "how do I know who's on the other side?".
- **New content — Notebook 04 "🚧 Backpressure":** explains why an
  unbounded `asyncio.Queue` per subscriber (what `sse_server.py` uses
  for clarity) breaks in production when clients are slow, and shows
  the three standard mitigations (bounded queue, drop-on-full,
  disconnect-slow-client). Reinforces the "transport ≠ durability"
  lesson introduced in Notebook 07.

## 2026-04-19 (follow-up QA pass)
- **Re-verified** all 8 notebooks execute end-to-end against the running
  `servers/*.py` + existing Redis container — every cell completes with 0
  errors.
- **docker-compose.yml:** removed the obsolete top-level `version: '3.8'` —
  Docker Compose v2 warns about it on every invocation.
- **README Quick Start:** added explicit instructions for (a) picking the
  `.venv` kernel in VS Code, (b) reloading the window if it doesn't appear,
  and (c) what to do when another lab is already using port 6379.
- **New content — Notebook 01 "In Production: TLS, `https://`, `wss://`":**
  beginners routinely ship `ws://` to a `https://` site and get blocked by
  the browser; this new section spells out the plain-vs-encrypted twins and
  the L7 load balancer implications.
- **New content — Notebook 07 "Synthesis: Transport ≠ Durability":** the
  series already showed SSE replay (NB 4) and webhook idempotency (NB 8) in
  isolation, but never stated the cross-cutting lesson. New table pairs
  every transport with the recovery strategy ("snapshot + stream") you need
  to bolt on for guaranteed delivery across disconnects.

## 2026-04-19 (pm QA pass)
- **Full notebook re-run:** executed all 8 notebooks end-to-end against the
  running `servers/*.py` + Redis; every cell completes with 0 errors.
- **Path fix:** README and notebooks 02–05 referenced the old
  `patterns/real-time-updates/servers` path — corrected to
  `04-patterns/real-time-updates/servers` to match the real tree.
- **New content — WebSocket heartbeats:** added a "💓 Keeping Connections Alive"
  section + runnable demo to `05_websockets.ipynb` that uses
  `websockets.connect(ping_interval=..., ping_timeout=...)` and measures
  round-trip time via `ws.ping()`. Closes a genuine gap — nothing in the lab
  previously covered how to detect silently-dropped WebSocket connections.

## 2026-04-19
- **QA pass:** recreated the uv-managed `.venv` (previous one had stale shebangs
  from a moved directory).
- **Notebook 04 fix:** the `demonstrate_reconnection` cell used to fail when the
  SSE server's idle-heartbeat timeout fired after the replay — wrapped the
  iteration in a try/finally and tightened the event count.
- **Notebook 05 fix:** the two-user chat demo hung forever because
  `async for message in self.websocket` never returned once both sides went
  silent. Switched to a polled `recv()` with a short timeout so `duration`
  actually stops the loop.
- **Notebook 05 cleanup:** dropped the `pip install websockets` fallback — the
  library is already installed by `uv sync`.
- **Notebook 07 fix:** the real-Redis Pub/Sub demo would hang on
  `subscriber_thread.join()` because `pubsub.listen()` blocks indefinitely once
  messages stop. Switched to `pubsub.get_message(timeout=0.5)` driven by the
  duration.
- **New content:** added `notebooks/08_webhooks.ipynb` and
  `servers/webhook_server.py` covering webhooks (HMAC signing, retries with
  backoff, idempotency, fast-ACK), closing the gap against
  `references/designgurus.md`.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
