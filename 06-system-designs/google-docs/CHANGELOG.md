# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21
Correctness pass on the collaborative-editing core. Every fix below was a real
defect: the notebooks ran cleanly and still taught the wrong algorithm.

- **NB1 — OT transform was not convergent.** The four position-shift rules
  violated TP1 in three ways: two inserts at the same position ended up in
  opposite orders on the two replicas; an insert inside a deleted range diverged
  outright; and overlapping deletes shifted position without shrinking length, so
  two users backspacing the same word deleted **twice as many characters as
  either asked for**. Rewrote `transform()` to break same-position insert ties on
  a **site id**, clip overlapping delete ranges (possibly to nothing), and **split
  a delete in two** around a concurrent insert — so it now returns a list of ops.
  Added an exhaustive TP1 sweep over all 529 concurrent op pairs on an 8-char
  document, run against both the naive and the fixed transform (naive: 24 pairs
  diverge; fixed: 0), plus a check that a duplicate delete no longer eats extra
  characters.
- **NB1 — honest limits.** Added a TP2 counterexample: four concurrent ops that
  the server can order two different ways, with the explanation that this is
  exactly why OT needs a single server imposing a total order. The three-user
  demo now replays all 6 arrival orders and asserts they converge.
- **NB2 — the CRDT was not a CRDT.** Three defects: (1) float position ids ran
  out of precision after ~55 nested inserts, so the 90-character demo gave 35
  characters the id `1.0` and a delete could tombstone the wrong one — position
  ids are now exact `Fraction`s; (2) `apply_remote` had no dedup, so
  at-least-once delivery duplicated characters — inserts are now keyed by a
  unique `(site_id, counter)` char id and re-delivery is a no-op; (3) the
  position tie-break compared against `self.site_id` (the *local* replica)
  instead of the incoming character's site, so two replicas sorted the same
  characters differently. Deletes now name a char id rather than a position, and
  a tombstone set handles a delete arriving before its insert.
- **NB2 — properties actually checked.** New cell asserts commutativity,
  associativity and idempotence over 300 random delivery orders of 11
  insert-and-delete ops from three sites, plus 50 orders with every message
  delivered twice, and demonstrates the duplicate-character bug a merge without
  the dedup check produces. Added a cell showing float precision collapsing, and
  an honest list of what the toy CRDT does not do (tombstone GC, causality,
  interleaving, per-character overhead).
- **Server — OT was dead code.** `handle_edit` compared the client's version
  against `doc["version"]`, which is the *snapshot* version and only moves every
  50 ops, and no client ever sent a version anyway — so concurrent ops were never
  transformed. Added a per-document `ops_log` whose length is the **revision**,
  sent in `doc_state`, quoted by clients on every edit, and returned in the ACK.
  Ported the corrected transform (list-returning) to the server.
- **Server — cursors are now transformed.** Every applied op shifts the other
  editors' stored cursors (in memory and in Redis) so a caret follows its
  character instead of sliding backwards when someone types above it.
- **NB3 — the lab never ran two concurrent clients.** Every "collaboration" demo
  waited for its own ACK first, so the server had nothing to transform. Added a
  demo where both clients fire an edit quoting the *same* revision (Alice
  prepends a label, Bob deletes the word underneath it), asserts they converge
  and that Bob's delete did not eat Alice's label, and prints what the
  untransformed server would have stored instead. Added a cursor-transformation
  demo that asserts the caret still points at the same character.
- **NB3 — "consistent hashing" was `hash % n`.** The routing demo was plain
  modulo hashing, which is the thing consistent hashing exists to replace.
  Replaced it with a real hash ring (virtual nodes, `bisect` lookup) and a
  server-failure measurement: modulo moves 81% of documents to lose one server
  of five, the ring moves exactly the 20% that lived on it. Both numbers asserted.
- **NB3 — receive races.** `DocClient` read one message blindly and checked its
  type, so any interleaved broadcast broke the demo. It now buffers by type
  (`wait_for`), applies remote ops and ACK-confirmed ops to its local copy, and
  tracks its revision. Every demo now asserts the two clients' texts match.
- **NB4 — prose contradicted the output.** The growth cell printed 92% savings
  and the recap claimed 94%; the number is now computed, and the model's
  worst-case assumption is stated instead of hidden in `h % 2 or 2`.
- **NB4 — "snapshots are more space-efficient" was backwards.** The printed table
  shows snapshot bytes exceeding op-content bytes, because every snapshot stores
  the whole document again. Rewrote the takeaway: compaction buys *load time*,
  and the storage win only arrives when the subsumed ops are archived.
- **NB4 — assertions.** Loading via snapshot+replay is now checked against a full
  replay from an empty document; `save_snapshot` is checked to have frozen the
  text the client actually had; restore is checked to reproduce the target
  version byte-for-byte *and* to append a new version rather than rewrite
  history. The diff cell now compares the two most recent versions instead of
  diffing against the empty v0.
- **Seed data — op positions were wrong.** Five of the eleven seed operations on
  document 1 had positions past the end of the document at the time they were
  created (93/114/137/176/208 instead of 91/111/134/174/206); replay only
  produced the right text because Python clamps out-of-range slices. Corrected,
  and NB1 now asserts that replaying the op log reproduces snapshot v1 exactly.
- Added an **Honest Scope** table to the README and "what this does not do"
  sections to the NB2/NB3/NB4 summaries.

Found by running the lab against real Docker (the first pass verified the
notebook logic in-process, which cannot see what PostgreSQL actually stores):

- **Seed snapshots were stored with literal backslash-n.** The `snapshots` rows
  used plain `'...\n...'` literals while the `operations` rows used `E'...'`.
  With `standard_conforming_strings=on` (the default) that means the snapshot
  held the two characters backslash+n where the ops held a real newline — so
  snapshot v1 was 250 characters and replaying the op log gave 238, and the two
  could never agree. It also meant NB4 printed the whole document on one line
  and diffed it as a single row. All snapshot literals are now `E'...'`.
- **The seed is now derived, not hand-written.** `db/init.sql`'s doc-1 ops and
  snapshot v1 are generated from a single list of edits, with the generator
  asserting that replaying the ops reproduces the snapshot and that no op
  position lands past the end of the document at the time it is applied. The
  op_count on snapshot v1 was also wrong (12 for 11 operations).
- **`broadcast_to_doc` crashed on a concurrent disconnect.** It iterated
  `doc_sessions[doc_id].items()` across an `await`, so a client closing during a
  broadcast raised `RuntimeError: dictionary changed size during iteration` and
  killed the connection handler mid-send. It now snapshots the session list
  first.
- **NB1's replay is scoped to `version = 0` ops.** It compares against snapshot
  v1, so it must replay only the ops that snapshot compacted; replaying every
  op for the document meant the assertion broke as soon as NB3 had appended its
  own edits (i.e. on any second run against the same volume).
- **`DocClient` now fails loudly on a stale server.** If `doc_state` has no
  `revision`, or an ACK has no `transformed`, the client says "rebuild the
  image" instead of silently applying nothing and diverging.

Verified: all four notebooks execute clean against the real stack, twice in a
row against the same volume (the demos clean up after themselves), with no
errors in the doc-server log.

## 2026-04-20
- Fixed NB1 three-user OT demo: replaced example with clearer positions so the
  final text reads naturally ("The brown fox and lazy dog jumps") instead of
  jammed-together words.
- Added **server-side role enforcement**: the doc server now rejects `edit`
  messages from users whose role is `viewer` (previously viewers could edit).
- Added a new permissions-demo cell to NB3 that verifies a viewer is blocked
  by the server — reinforcing "never trust the client".
- Added a new diff-between-versions cell to NB4 that uses `difflib` to show
  what changed between two snapshots (how "Show revision history" works).

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
