# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21

Correctness pass over the money paths. The lab ran cleanly before this; it was
not correct.

- **Notebook 1 — the matching engine was losing executions.**
  - `add_market_order()` returned its fills but never called `_record_trade()`,
    so a market order's counterparty side existed nowhere in the trade log. Every
    fill is now recorded.
  - Heap keys were `(price, timestamp, order)`. Two orders sharing a wall-clock
    timestamp made `heapq` fall through to comparing `LimitOrder` objects and
    raise `TypeError`; `display()` had the same problem sorting two orders at the
    same price. Added a monotonic `seq` arrival counter as the tie-breaker and
    sorted on price explicitly.
  - A market order that outruns the book used to drop the residual silently. It
    is now recorded in `unfilled` (market orders never rest) and reported.
  - Added `best_bid()` / `best_ask()` / `spread_cents()` and a `check_invariants()`
    that runs after **every** order: the book is never crossed, both sides of the
    trade log sum to the same total, and every submitted share is either executed,
    resting, or explicitly unfilled.
  - New section **"Price-Time Priority (and What a Partial Fill Must Not Do)"**,
    proving best-price-first, FIFO at equal price, and that a partial fill keeps
    its queue position instead of going to the back of the line.
  - `simulate_trade_fill()` wrote the trade row and the status change under
    autocommit, and a replayed fill from the at-least-once trade feed created a
    duplicate trade. Now one transaction, `SELECT ... FOR UPDATE`, and idempotent.
  - `cleanup_stuck_orders()` marked orders `filled` **without writing a trade
    row** — the reconciler-with-no-ledger-entry bug. It now writes the execution
    in the same transaction, and the coin-flip `random.choice()` was replaced with
    a deterministic simulated exchange lookup that resolves one stuck order to
    `filled` and one to `failed`.
- **Notebook 2 — the portfolio drifted from the ledger.**
  - `process_trade()` claimed in its own docstring (and in the summary) to
    "record the trade", but never inserted into `orders` or `trades`; it only
    moved the position and the cash. All four writes now happen in one
    transaction.
  - The average-cost worked example in prose said `$181.92`; the code's floor
    division printed `$181.91`. Switched to integer round-half-up so the two
    agree, and documented the sub-cent drift that any single `avg_cost_cents`
    column implies.
  - The caching section claimed the portfolio cache is invalidated on every
    trade; nothing invalidated it. `process_trade()` now drops the key after the
    commit.
  - Added an **Audit** cell: every demo order is backed by trade rows summing to
    `filled_quantity`, positions match the weighted-average arithmetic, and both
    cash balances match the traded notional exactly.
  - Seeded the O(n)-vs-O(1) timing demo's RNG, asserted the speedup actually
    happens, and asserted a full rescan of the 5,000 trades agrees with the
    materialized `positions` rows.
  - Cleanup now removes the orders/trades the notebook wrote, not just positions.
- **Notebook 3 — the pipeline could deliver nothing and still look fine.**
  - The end-to-end demo raced the producer against the consumer with
    `auto_offset_reset='latest'`, so trades produced during the group join were
    skipped — it lost the first message or two roughly one run in three, with no
    error anywhere. `'latest'` is not resolved at construction or even at group
    join: it is resolved by a ListOffsets round-trip issued on the first fetch
    *after* assignment, and `seek_to_end()` only re-arms that same lazy reset
    (`SubscriptionState.need_offset_reset`). No external handshake can close that
    gap. Fixed by removing `'latest'` entirely: the demo now produces to a topic
    of its own and reads it from `earliest`, so "everything in the log" and
    "everything this run produced" are the same set by construction. The notebook
    explains why, and points at the production answer (commit offsets and resume
    from them).
  - **The trade-feed producer was silently losing trades.** `simulate_exchange_feed`
    called `producer.send()` and never looked at the returned future, and
    `KafkaProducer` defaults to `acks=1` and **`retries=0`**. Because the topic was
    auto-created *during* the first produce, the opening records raced the new
    partition's leader election and were dropped with no exception raised
    anywhere — a repeat run put 11 of 15 trades in the log while the notebook
    cheerfully printed "15 trades published". Fixed three ways: topics are created
    up front via a new `ensure_topic()` helper, the producer now uses
    `acks='all'`, `retries=5` and `max_in_flight_requests_per_connection=1` (so
    retries cannot reorder the tape), and every send future is resolved and
    counted before the feed claims success. Only found because the end-to-end
    assertion was run repeatedly rather than once.
  - Kafka topics are now per-run (`trades-<epoch>`). The notebook previously
    shared one durable `trades` topic, so a second execution replayed the first
    execution's trades and every count was off. Cleanup deletes both topics.
  - Every Redis subscriber signalled readiness with a `time.sleep()`, which is a
    guess rather than a handshake — a `PUBLISH` landing before `SUBSCRIBE` is
    registered is dropped silently. All three subscribers (fan-out demo, pipeline
    demo, polling comparison) now block on Redis's own SUBSCRIBE acknowledgement.
  - The pipeline cell asserts all 10 trades reach the subscriber and that Redis
    holds the last price per symbol; the price-processor cell asserts it consumed
    all 15 trades rather than timing out mid-stream.
  - Added assertions to the pub/sub fan-out demo (4 updates received, META never
    delivered) and to the polling-vs-pub/sub demo (one message vs eight requests,
    polling latency within one poll interval, pub/sub at least 10x faster).
  - The polling demo fired its price change from a timer thread, so the measured
    polling latency was a coin flip on where in the poll cycle the change landed —
    it could come out below the pub/sub latency and trip its own assertion. The
    change now fires immediately *after* a poll returns, which is the worst case
    the poll interval implies and is reproducible: ~250 ms vs ~0.2 ms every run.
  - Seeded the trade-feed RNG, swapped `int()` for `round()` (truncation drifted
    every price downward), and made the up/down arrow reflect the move that
    actually happened rather than the pre-rounding percentage.
  - New **Backpressure** section: Redis pub/sub has none, a slow subscriber gets
    its output buffer capped and disconnected, and the fix is conflation rather
    than queueing — which is also why Kafka sits upstream, not downstream.
- **`db/init.sql`** — the five seeded `filled` orders had no `trades` rows behind
  them, so positions could never be reconciled against history. Added the matching
  executions. Run `docker compose down -v && docker compose up -d` to pick this up
  on an existing volume.
- **README** — documented price-time priority, the one-transaction rule, and an
  "Honest Limits of This Lab" section (no settlement, no lot-level cost basis, no
  short positions, no self-trade prevention, no SSE server, no conflation).

## 2026-04-20
- Switched `docker-compose.yml` Kafka image from the unavailable
  `bitnami/kafka:3.7` to `confluentinc/cp-kafka:7.6.0` (KRaft mode), matching
  the ad-click-aggregator lab and the `03-technologies/messaging/kafka` lab.
- Notebook 1 — added two bad→best sections with runnable demos:
  1. "Money Should Never Be a `float`" (float drift vs integer cents).
  2. "Idempotency Keys for Order Placement" (retry creates duplicate order
     vs `client_order_id` + `UNIQUE` index de-dup).
- Notebook 2 — added a bad→best timing demo that compares recomputing
  positions by scanning every trade (`O(n)`) against reading the
  materialized `positions` table (`O(1)`).
- Notebook 3 —
  - replaced deprecated `datetime.utcnow()` with `datetime.now(timezone.utc)`;
  - made Kafka consumer `group_id`s unique per run so re-executing the
    notebook isn't affected by committed offsets from earlier runs;
  - added a bad→best "Polling vs Pub/Sub" section that measures request
    volume and price-change latency for both approaches.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
