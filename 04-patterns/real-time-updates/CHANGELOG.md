# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

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
