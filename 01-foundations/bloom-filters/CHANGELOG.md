# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Bloom Filters` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.
- Added three notebooks covering core concept, sizing math, and cache/DB application.
- Added notebook 4 on **counting** and **scalable** bloom filters, including a demo that
  deterministically reproduces the false-negative bug caused by naive deletion.
- Enhanced notebook 2 with an "optimal `k`" plot showing the FPR minimum at `k* = (m/n) ln 2`.

## 2026-08-20 (correctness audit)
- Verified the sizing math end-to-end: `m = -n ln p / (ln 2)^2`, `k = (m/n) ln 2`, and
  `FPR = (1 - e^(-kn/m))^k` now assert against each other and against measured rates.
- NB1: replaced printed "false negatives: 0" with an assertion, and added a
  measured-vs-theoretical FPR comparison (plus a note on why the textbook formula
  slightly *under*states FPR in a badly overloaded filter).
- NB2 **(new section)**: proved the double-hashing family is genuinely independent by
  racing it against a deliberately correlated one (`h_i = h1 + i`), which measures
  **23%** FPR against a 1% design target with identical `m` and `k`.
- NB3: asserted that no legitimate user is ever rejected, and that false-positive
  leak-through stays inside the 1% budget.
- NB4: asserted the naive-delete false negative actually occurs; asserted counting
  counters cannot underflow and that `remove()` refuses unknown items; **added a demo
  of the hazard counters do not fix** — removing a false positive destroys a real
  member. Asserted the scalable filter's geometric growth and compound FPR budget.
- Hygiene: kernelspec set to `Python 3 (.venv)`, saved outputs stripped.
