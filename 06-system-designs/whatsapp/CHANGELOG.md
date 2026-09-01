# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21

Content-correctness review. Almost every fix below is a defect in what the lab
*taught*, not in whether it ran — all four notebooks reported clean execution
before this pass. "Reported" is doing real work in that sentence: Notebook 3 was
leaving a permanently wedged receiver thread behind, and because the cell joined
with a timeout and printed a partial result, nbconvert called it a success. The
assertions added here are what turned that from invisible into a hard failure.

**Server (`server/chat_server.py`)**
- **Per-conversation ordering was not actually guaranteed.** `store_message` allocated the sequence number in one transaction and inserted the message in another, so two concurrent senders in the same chat could commit in the opposite order to their sequence numbers. Sequence allocation, the message insert, and the inbox fan-out now happen in **one transaction**, so the row lock on `chat_sequences` holds until commit and sequence order == commit order. The fan-out is also a single `INSERT ... SELECT` instead of a row-at-a-time loop.
- **`sync` returned the backlog in `server_timestamp` order**, which can disagree with the per-chat sequence. Now `ORDER BY m.chat_id, m.sequence_number` (which also matches `idx_messages_chat`).
- **A crashed client lost its "last seen".** `last_seen` was written only by `set_offline()`, i.e. only on a *clean* disconnect. A phone that dies leaves the presence key to expire and nobody calls `set_offline`, so the user showed as *"offline · last seen: never"*. `set_online()` now stamps `last_seen` on every presence refresh.
- **Read receipts could be reached with `delivered_at` NULL.** `handle_read` now backfills `delivered_at = COALESCE(delivered_at, NOW())` and is a no-op on a repeated read, so `read_at` records the first read.
- **The sender was never told ✓✓.** `handle_ack` now publishes a `delivery_receipt` to the sender on the pending→delivered transition (mirroring `read_receipt`), so the checkmark progression is observable end-to-end rather than only by querying the DB.

**Notebook 1 — Message Delivery & Storage**
- **The gap-detection demo could never find a gap.** It ran `detect_gaps` against the *server's* `messages` table, which is a dense `1..N` run by construction, so it printed "✅ No gaps" for every chat and demonstrated nothing. Rewritten to model a **client**: messages are reordered in flight (seeded RNG), the scrambled render is shown and asserted, sorting by `sequence_number` repairs it, then one message is dropped and the gap is detected. Includes the honest caveat that a message lost at the *tail* is invisible to this check.
- Added **§ At-Least-Once Is Not Exactly-Once**: reproduces a real duplicate by retrying a send against the live server, then fixes it with a client-minted `client_message_id` and a partial unique index on `(sender_id, client_message_id)`. Explains why a server-generated id cannot work.
- Prose now states that ordering is **per conversation, not global**, and why that is both cheaper and sufficient.

- **The pub/sub forwarder blocked the entire event loop, and the lab's headline latency claim was false.** `redis_subscriber` polled Redis with `pubsub.get_message(timeout=0.5)` — a *blocking* socket read — from inside an asyncio task. That stalls not just one user but the whole server, and the cost compounds with every connected client. Measured against the running stack: a delivery receipt took a **median of 3,518 ms with five connections**, while Notebook 1's back-of-envelope advertises `~50ms` for this architecture. Switched to a non-blocking poll (`timeout=0`) that drains the backlog in a tight inner loop and yields between idle passes. Same measurement after: **median 6 ms** (min 6, max 9) — a ~580x improvement, and the `~50ms` claim is now true rather than aspirational. This was also the real cause of the intermittent notebook failures on a loaded machine: the receipts genuinely were not arriving within a few seconds.

- **Publish-before-subscribe race on connect.** The handler replied `connected` as soon as it *scheduled* the Redis subscriber. `pubsub.subscribe()` only writes bytes to a socket, so a client could be greeted, immediately act, and have the resulting event published into a channel Redis had not yet registered it on — silently dropped, since pub/sub keeps no backlog. The subscriber now reads the SUBSCRIBE confirmation and the handler waits for it (bounded, 5s) before greeting the client. This is the same trap the lab teaches about pub/sub, and the server was falling into it.

**Notebook 2 — Read Receipts & Presence**
- Added **§ 3b: Why Receipts Never Run Backwards** — a runnable demo of the two cases that break a naive implementation: a stale ACK arriving after the read (must not downgrade `read` → `delivered`), and a `read` with no preceding ACK (must backfill `delivered_at`).
- Step 7 now receives **both** receipts and asserts they arrive `delivery_receipt` → `read_receipt`; previously it read a single frame and could not show the ✓✓ step at all.
- Added **§ the client that dies without disconnecting** — connects Alice, kills her socket without a close frame, and asserts that presence self-heals via TTL *and* that `last_seen` survives. Also states the honest cost: status is stale for up to one lease period.
- Fixed a comment claiming Bob received a message via pub/sub when he was not yet subscribed (the point of that step is that the inbox replays what pub/sub dropped).
- Fixed duplicated **"Section 7"** headings (typing indicators → 8, media handling → 9).

**Notebook 3 — Group Messaging**
- **`03:11` deadlocked, and the lab never noticed.** The receiver treated the WebSocket as request/response: it ACKed *inside* the receive loop and then called `recv()` to "consume the ack_ok". A WebSocket is a stream — the server had already queued `sync_complete` behind the `new_message` frames, so that `recv()` swallowed `sync_complete`, the loop then read the real `ack_ok`, matched neither branch, and blocked forever. With one pending message the thread hung outright; with two it silently dropped a message. Because the threads were non-daemon and joined with a timeout, the cell *printed a partial result and passed* — a hung thread was the only trace. Rewritten into two explicit phases (drain the backlog until `sync_complete`, then ACK and match replies by `message_id`), with daemon threads, bounded `recv` timeouts, and assertions that no thread is still alive and none errored.

- **`max_participants` claim contradicted the schema.** The table said 1:1 chats are capped at 2 and groups at 100; `db/init.sql` uses a single default of 100 for all chats. Corrected, with a note on what actually makes a chat 1:1.
- **"WhatsApp traffic is ~95% 1:1 messages" contradicted the notebook's own parameters** (`pct_group_messages = 0.20`, i.e. 80% 1:1). The 95% figure describes the mix of *chats*, not *messages*. Prose rewritten to argue the real reason by-user wins (a PUBLISH is an event-proportional one-off; a subscription is resident state), and the two ratios are now printed side by side so they cannot be conflated again.
- `pct_one_to_one` was declared, printed, and never used; the distinct-chat count now derives from it properly instead of assuming every chat has exactly 2 members.
- Documented the unstated ~1 ms-per-inbox-row assumption behind the scaling table's latency column.
- Cleanup did not restore the seeded inbox rows that Bob and Charlie ACKed, so "back to its original state" was false and Notebook 1's prose would be wrong on the next run.

**Notebook 4 — End-to-End Encryption**
- **Envelope encryption used unauthenticated AES-CBC** with hand-rolled padding — confidentiality with no integrity, the root of the padding-oracle family of bugs — and left a dead `key_bundle` variable. Switched to **AES-256-GCM**, which removes the manual padding and adds an auth tag; the cell now proves the tag catches a single flipped bit. The cost comparison is corrected too: envelope encryption does **not** reduce the number of RSA operations, it makes each one constant-sized and lifts RSA-OAEP's ~190-byte message ceiling.
- **"RSA-2048 has 2^2048 possible keys"** — nobody enumerates RSA keys; you factor the modulus. Replaced with the actual figure: GNFS puts RSA-2048 at roughly **112-bit** security.
- **Sequence allocation was a read-modify-write race** (`SELECT last_sequence` then a separate bump). Replaced with a single atomic `UPDATE ... RETURNING`, matching the server.
- Cleanup left the sequence counter permanently ahead of the stored messages; it is now rewound and verified.
- Fixed a hardcoded setup path pointing at `system-design-labs`, a repo that does not exist.

**Schema & README**
- `db/init.sql`: the inbox comment claimed rows are *deleted* on ACK; the code has always updated `status`. Corrected, and added the `client_message_id` column plus its partial unique index for fresh volumes.
- `README.md`: same "rows deleted on ACK" error in two places; corrected. Added an explicit **"What This Toy Does NOT Do"** section (single chat server, at-most-once pub/sub, no forward secrecy, presence is pull-only, inbox rows are never pruned) so the lab stops overselling itself.

**Verified against real infrastructure** — `python tools/run_labs.py 06-system-designs/whatsapp` → `PASS ... 4 notebooks`, on a rebuilt image and a fresh volume, with zero error outputs. Confirmed from the executed copies that the demos actually demonstrate their lessons rather than passing vacuously: the reorder demo really scrambles (`[3, 2, 4, 1]` → `[1, 2, 3, 4]`), the gap demo really finds `[3]`, the retry really stores two rows before the idempotency key collapses it to one, both receipts really reach Alice in order, and the crashed client really keeps a usable `last_seen`.

**Assertions added throughout** — every lab now fails loudly if it stops reproducing its own lesson: fan-out size, per-chat sync ordering, receipt monotonicity, `delivered_at` backfill, presence-after-crash, idempotency (exactly one row, same id, only the first attempt inserts), the partitioning recommendation still following from the parameters, AES-GCM tamper detection, cross-recipient decryption failing, and each notebook's cleanup genuinely restoring the seed state.

## 2026-04-20
- Notebook 1: Added a **bad → best progression** section contrasting HTTP polling vs WebSocket-only vs WebSocket+inbox+pub/sub, with back-of-envelope math showing polling does ~432× more work per delivered message.
- Notebook 2: Added **Section 7 — Typing Indicators** (pure Redis pub/sub, no DB writes) with a runnable ephemeral demo.
- Notebook 2: Added **Section 8 — Media Handling** covering object-storage + signed-URL uploads, schema additions, and E2E-encrypted media considerations.
- Added `tabulate` dependency to `pyproject.toml` so Notebook 3 (Group Messaging) runs without `ModuleNotFoundError`.
- Verified all 4 notebooks execute end-to-end with zero errors against the Docker stack.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
