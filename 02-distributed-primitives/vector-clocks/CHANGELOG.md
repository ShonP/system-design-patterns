# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Vector Clocks` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- Added notebooks `01_lamport_clocks.ipynb` and `02_vector_clocks.ipynb`.
- QA pass: added setup cells (kernel picker instructions), deterministic wall-clock "bad baseline" in NB1, matplotlib space-time diagram, vector notation printed as `[A=…, B=…, C=…]` for clarity, runnable Dynamo shopping-cart example in NB2 contrasting last-write-wins vs vector-clock merge, real-world comparison table (Dynamo/Riak, Cassandra, Git, CRDTs), and mini-exercises in each notebook.

## 2026-08-20
- Added a property check that the comparison is a genuine **partial** order — reflexive,
  antisymmetric, transitive, and leaving ~40% of random pairs incomparable. A total order
  (comparing sums, or tuples lexicographically) is the classic bug and would score zero
  concurrent pairs while still answering the worked examples correctly.
- **Robustness fix:** `compare()` returned prose that `merge()` then matched with
  `str.startswith`, so rewording a sentence would have silently turned the conflict detector into
  a last-write-wins store. It now returns tokens.
- Added assertions that Lamport respects happens-before but cannot express concurrency, that the
  wall-clock timeline really is causally inverted, and that the cart merge is idempotent and
  commutative with a clock dominating both siblings.
- Ran the "why union breaks under remove" exercise instead of leaving it as homework, with a
  tombstone-based fix.
