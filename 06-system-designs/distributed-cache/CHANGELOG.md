# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21 (content-correctness review)
- **Fix (NB1)**: the "modulo hashing moves ~75% of keys on ANY resize" claim contradicted
  the table printed directly above it, which showed 49.8% (3→6), 91.0% (10→11) and 98.0%
  (50→51). Replaced with the correct N/(N+1) law, plus an explanation of why doubling is
  the lucky exception. Same fix applied to the takeaways table.
- **Fix (NB1)**: the range-partitioning table and print label claimed the 3-node split was
  `a–h / i–p / q–z`. With `26 / 3 ≈ 8.67` letters per node the real split is `a–i / j–r /
  s–z`, so `ivy` and `quinn` were routed to the wrong node in the printed demo. The cell now
  computes and prints the actual boundaries instead of trusting a hand-written table.
- **Fix (NB1)**: the range-partitioning demo used 24 names, one per letter a–x -- uniform
  over the alphabet *by construction*, so it could not show the hot spot its own prose
  claimed. Swapped for 40 real first names, which land 13 / 21 / 6 (3.5× imbalance).
- **Fix (NB1)**: the consistent-hashing preview built a ring with one position per node and
  reported only key *movement*, silently teaching that such a ring is fine. It gave node-2
  55.8% of the keyspace and node-1 9.8%. The cell now prints that distribution and points
  forward to virtual nodes in Notebook 3.
- **Fix (NB3)**: "With ~150 virtual nodes, deviation is typically under 5%" was false --
  the sweep's own single-sample run measured 14.4% at 150 vnodes, *worse* than at 100. Root
  cause: one ring per vnode count is a sample of size 1, so where three node names happen
  to hash swamps the effect being measured, and the curve came out non-monotonic. The sweep
  now averages 12 independently-salted clusters per row (which is monotone), keeps the
  single-sample column visible so the noise is the lesson, and states the honest number:
  ~8% at 150 vnodes on a 3-node cluster, shrinking like 1/√(vnodes) and never to zero.
- **Fix (NB3)**: `add_node` wrote colliding ring positions into a dict (one owner) and a
  list (two entries), so a later `remove_node` could leave a dangling position pointing at a
  deleted node. Colliding positions are now skipped so both structures stay in lockstep.
- **Fix (NB2)**: the async-replication coherence demo flushed every node before writing, so
  the "stale" replica was actually *empty* -- a cache miss, which is safe, not the stale
  wrong answer the lesson is about. It now seeds the old price on all replicas first, so the
  lagging replica genuinely serves the previous value.
- **Fix (NB2)**: the pub/sub invalidation listener had two related wall-clock bugs, both
  caught by running the lab against real Redis. (a) `pubsub.subscribe()` only *sends* the
  SUBSCRIBE command; the server registers it a moment later, and the cell's fixed
  `time.sleep(0.5)` was not always enough -- publishing to zero subscribers. It now polls
  `PUBSUB NUMSUB` until every node confirms a listener, bounded, with the observed counts in
  the timeout message. (b) The listener thread ran a blocking `for message in
  pubsub.listen()`, which never returns, so three threads outlived their cell and later
  raised `ValueError: I/O operation on closed file` writing into a torn-down stdout. The
  loop is now a bounded `get_message(timeout=...)` poll driven by a stop flag, the threads
  are joined in a `finally`, connections are closed, and the cell asserts none is still
  alive.
- **Fix (NB2)**: comment said "100ms delay" while the call passed `delay_ms=500`; the
  staleness poller used an unbounded `while True` that would hang the notebook forever if
  the replication thread died; the pub/sub section implied a shared channel when three
  standalone Redis servers mean three separate channels and a fan-out publisher.
- **Fix (NB4)**: the write-through diagram showed `cache.set` before `db.write` while the
  code did the opposite. Diagram corrected, and the cell now proves the ordering by failing
  a DB write and asserting no phantom cache entry is left behind.
- **Fix (NB3)**: `random` was used unseeded in the hot-key copy demo; seeded for reproducibility.
- **Added (NB4)**: Part 5b, **TTL jitter**. The lab reproduced the one-key thundering herd
  but never the many-keys-one-instant version that a single-flight lock cannot touch. New
  section simulates a cold start warming 10,000 keys with a fixed TTL: the burst peaks at
  2,046 misses/s and *never decays*, while ±10% jitter drops it to 200/s and keeps
  flattening. README and takeaways updated.
- **Added**: assertions throughout all four notebooks so each lab fails loudly if it stops
  reproducing its own lesson -- among them: hash-ring wraparound past the last position;
  every key moved by a scale-up went *to the new node* (no shuffling between existing
  nodes); a node crash moves exactly the dead node's key count, not one key more; movement
  tracks 1/N at every step from 3→10 nodes and the per-node cost keeps falling; the naive
  stampede really does trigger ~20 DB reads and single-flight collapses it to exactly 1;
  cache-aside-without-invalidation really does go stale; write-behind really does leave the
  DB behind; the negative-cache sentinel never leaks to callers.
- **Added (NB3)**: an honest "what this toy ring does NOT do" section -- no replication, no
  capacity weighting, no membership protocol, no actual data movement -- and a note that a
  crash redistributes the dead node's keys *unevenly*, which can create a hot survivor.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: added the missing `numpy` dependency to `pyproject.toml` -- the notebooks import it, so a fresh `uv sync` produced a lab that failed on `ModuleNotFoundError`.
- **Fix**: the notebooks were pinned to an unregistered Jupyter kernel named `distributed-cache`, raising `NoSuchKernel` on open. They now use the lab's own `.venv`.

## 2026-04-19
- Added Notebook 4: **Cache Patterns & Stampede Protection** covering cache-aside,
  read-through, write-through, write-behind, thundering-herd stampedes fixed with a
  Redis single-flight lock (`SET NX EX` + token + Lua compare-and-delete), and
  negative caching with a sentinel value.
- README updated with the new notebook and two new concept sections.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
