# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21 (correctness audit)

A lab that runs cleanly is not necessarily a lab that is right. All 8 notebooks
executed with 0 errors before this pass; the defects below were found by reading
the prose against the code and the numbers the code would actually print.

### Prose that disagreed with the code

- **NB 01 cell 4** — `demonstrate_udp_simplicity()` printed *"📤 Sending UDP
  packet..."* and never called `sendto`. It now really sends on loopback, and
  then sends a second datagram to a port where nothing is listening to show the
  actual UDP lesson: `sendto()` returns normally and the sender cannot tell.
- **NB 01 cell 6** — asserted *"first request is slower"* from 3 samples over the
  public internet, and crashed with a raw `ConnectionError` when offline. Now
  measures medians over 7 samples, excludes the session's handshake-paying first
  request, prints the measured saving (or "inconclusive"), and skips cleanly
  with an explanation when there is no network.
- **NB 02 cell 15 / NB 01** — the keep-alive comparison only printed a verdict
  when keep-alive won, so a losing run silently said nothing. Now 40 samples,
  medians, and an honest verdict either way. The closing note was rewritten to
  match what the cell actually prints (58% on loopback, not "tiny").
- **NB 06 cells 11 & 17, README** — "Google Docs uses WebRTC for presence" and
  "WebSockets + CRDT" are both wrong. Google Docs syncs through Google's servers
  using operational transforms; the P2P-CRDT example is now Excalidraw/y-webrtc,
  with the reason the server stays in the loop for Docs (it is also the durable
  store and the permission check).
- **NB 07 cell 19/21** — the "~10 ms extra Pub/Sub hop" figure is now measured by
  the Redis cell (publish → deliver) instead of quoted.
- **NB 08 cell 16** — `# at most 1 payment per poll` described the opposite of
  what the line computes (it is an upper bound on *useful* polls). Reworded, and
  the cell now also states the cost side of the trade: 720 outbound reads become
  100 inbound authenticated writes plus a reconcile job.

### Demos that could not demonstrate their own lesson

- **NB 02 cell 12** — `measure_polling_efficiency()` polled an idle server and
  concluded "most polls return nothing". With nothing ever published, 0% useful
  was guaranteed, not measured. One message is now published mid-run from a
  background thread; the cell reports a real 1/10 hit rate and **asserts** both
  that the message arrived and that ≥8 polls were still wasted.
- **NB 03 cell 8** — used `client.timeout = 10` against a 30 s server hold, so
  the *client* aborted and the notebook labelled it "Server had nothing to send"
  — while cell 15 taught the opposite rule (server timeout < client timeout).
  Added `?max_wait=` to the server so a demo can shorten the **server**'s hold;
  the cell now holds for 5 s with a 35 s client timeout and **asserts the
  connection was genuinely held open** (`elapsed > 0.8 × hold`), which is the
  one thing separating long polling from short polling.
- **NB 03 cell 11** — claimed "each message required a new long-poll request"
  without measuring anything. Now measures two regimes: messages published
  *during* a held poll (one round trip each, ~2 ms latency on loopback) and a
  backlog published *between* polls (all three in one response), and states that
  the reconnect gap — not the message count — is the real cost.
- **NB 04 cell 6** — `listen(duration=5)` could only notice the deadline when a
  line arrived, so on a quiet stream it sat for 15 s waiting for the server's
  heartbeat. Added `?heartbeat=` to `sse_server.py`; the client now requests a
  1 s heartbeat and **asserts `duration` is honoured**.
- **NB 04 cell 17** — the Last-Event-ID demo printed data lines and declared
  success. It now collects the replayed ids and asserts they equal *exactly* the
  ids missed while offline — a replay that returned nothing, or everything,
  previously printed something plausible either way.
- **NB 07 cell 6** — `simple_hash_assignment` used Python's builtin `hash()`,
  which is salted per process, so the printed assignments changed on every
  kernel restart and "😱 Almost ALL users moved" was luck over 5 names. Switched
  to a stable MD5 digest and measured churn over 10,000 keys: 75.1% for modulo
  vs 26.1% for the ring, asserted against both the theoretical 1/N share and the
  modulo baseline. Per-server load is now printed too (that is what virtual
  nodes buy).

### Security defects

- **NB 08 (receiver)** — `/hook` accepted **any** POST without checking the
  signature; verification happened afterwards, in the notebook, as commentary.
  That is a public unauthenticated write endpoint, not a simplification. The
  receiver now verifies before doing anything and returns 401, and Step 5 was
  rewritten to *attack* it: unsigned request, tampered body with the real
  signature, signature from the wrong secret, and a genuine request replayed an
  hour later — all refused, with a correctly-signed control that must still be
  accepted.
- **`webhook_server.py`** — signed the body only, so a captured delivery stayed
  valid forever. Now signs `"<timestamp>.<body>"` (the Stripe scheme) and sends
  `X-Webhook-Timestamp`; the receiver rejects anything older than 5 minutes.
  This also makes the notebook's "exactly what Stripe does" claim true.
- **NB 08 (new Step 6b)** — the notebook told you three times to dedupe on
  `delivery_id` and never did it. Added an idempotency ledger to the receiver
  and a cell that delivers the identical signed event three times and **asserts
  exactly one order ships**, plus the reason a duplicate must be answered 200
  and not 409.
- **NB 05 cell 17** — the "authentication" demo validated the token
  *client-side* and only simulated the rejection, teaching the one pattern that
  cannot work. `websocket_server.py` now validates the token on the join frame
  and calls `close(1008, "invalid token")`, and takes the username **from the
  token**, ignoring what the client claimed. The cell asserts all three: valid
  token accepted, forged token closed with 1008, and a client claiming
  `"admin"` with Alice's token still identified as `alice`.

### Server bugs

- **`long_polling_server.py`** — `post_message` was a sync `def`, so FastAPI ran
  it in a worker thread: it called `asyncio.Event.set()` cross-thread on a
  loop-owned Event, and a message published between a poll's "nothing new" check
  and its event registration was lost, parking that client for the full 30 s.
  Both handlers are now `async def` on the one loop thread, which makes the
  check-and-register sequence atomic. Verified with a 30-iteration race harness:
  0 missed wakeups.
- **`websocket_server.py`** — `broadcast_to_room` iterated a `set` across
  `await client.send(...)`, so a concurrent join or leave raised *"Set changed
  size during iteration"* mid-broadcast. Now iterates a snapshot. Also: empty
  rooms are removed instead of accumulating forever, and a malformed JSON frame
  returns an error to that client instead of killing the connection.
- **`sse_server.py`** — a non-numeric `Last-Event-ID` (anything a client echoes
  back) raised and returned 500. Now falls back to "start from the beginning".
  Added the `retry:` field on connect, which notebook 4 documented but the
  server never sent.
- **`lab_servers.py`** — child servers were started with `stderr=PIPE` and the
  pipe was never drained. uvicorn logs to stderr, so a chatty or crash-looping
  server fills the ~64 KB pipe buffer and then blocks mid-write, with no
  indication why. Output now goes to a temp file that is read on failure and
  deleted on shutdown. `stop_all()` also now waits after `kill()` (a zombie
  child kept the port appearing "listening") and closes the log handle.
- **NB 07 cell 16** — when Redis was down the cell printed a friendly "❌ Redis
  not running" and then died two lines later on `r.publish`. It now skips
  cleanly, so the series runs with no Docker at all.

### Assertions added (the lab now fails loudly if it stops teaching its lesson)

| Notebook | Assertion |
|---|---|
| 02 | one published message is delivered; ≥8 of 10 polls still wasted |
| 03 | the poll is held ≥ 0.8 × the server hold time; it wakes within 0.5 s of the publish; the burst takes one round trip per message; a backlog returns in exactly one response; the robust loop delivers both messages with 0 errors |
| 04 | 3 messages on one stream, all carrying `id:`; `duration` honoured; 5 burst messages under 1 s worst-case latency; replayed ids **equal** the missed ids; no SSE stream left open at the end |
| 05 | 3 sends × 2 room members = 6 deliveries; 3/3 pongs; valid token accepted, forged token closed 1008, claimed username ignored |
| 07 | the `since` cursor delivers each write exactly once; modulo churn > 60%; ring churn < half of modulo **and** within the theoretical 15–40%; each pub/sub message reaches exactly the server holding the recipient; 3/3 Redis messages across both channels |
| 08 | 2 deliveries accepted and none rejected; 4 attacks refused + control accepted; retry sequence is exactly `503, 503, 200` with one shared `delivery_id` and ≥1.5 s of real backoff; 3 identical deliveries ship exactly 1 order |

### Not changed (and why)

- **`webhook_server.py` `/trigger` blocks until the retry schedule finishes.**
  A real vendor enqueues and returns immediately. Left synchronous on purpose so
  the notebook can observe the whole attempt sequence in one cell — now called
  out in a comment rather than left as a silent inaccuracy.
- **Retry backoff has no jitter.** Production needs it (otherwise every receiver
  that failed during the same outage retries in lockstep); omitted here so the
  notebook's timing assertion is reproducible, and stated as such in the prose.
- **`sse_server.py` keeps an unbounded `asyncio.Queue` per subscriber.** NB 4's
  backpressure section already explains why this breaks in production and lists
  the three mitigations; bounding it would make that section's example stop
  matching the code it describes.
- **The WebSocket server still accepts a `join` with no token**, so the earlier
  notebooks keep working. Flagged in NB 5 as the anti-pattern it is ("auth is
  optional" = "no auth") rather than silently allowed.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: notebooks 2, 3, 5 and 8 required you to start a FastAPI/websockets server by hand in a second terminal. If you did not, the notebook politely printed *"Server is not running"* and then crashed on the very next cell with a raw `ConnectionError`. Added `servers/lab_servers.py` with an idempotent `ensure_server(port)` that starts the right server in the background using the notebook's own interpreter and shuts it down when the kernel exits -- a server you started yourself is left alone.
- All 8 notebooks now execute end-to-end (previously 4 failed).

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
  `04-patterns/real-time-updates/servers` path — corrected to
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
