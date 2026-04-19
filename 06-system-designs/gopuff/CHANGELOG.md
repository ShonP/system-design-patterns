# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- NB1: Added a deterministic "naive (non-transactional) order" demo that oversells to
  `quantity = -1` using `threading.Barrier`, giving a concrete bad→best progression
  against the existing `SERIALIZABLE + FOR UPDATE` version.
- NB1: Added `place_order_with_retry` wrapper with exponential backoff + jitter for
  `SerializationFailure`, plus a real-world note on inventory reservations/holds.
- NB2: Added a Euclidean-vs-Haversine error table (local + regional distances) to
  motivate Haversine without overselling the difference at neighborhood scale.
- NB2: Added a matplotlib scatter plot of DCs with 5mi coverage circles + customer star.
- NB2: Added callouts on courier availability affecting real ETAs and a short
  "further reading" note on Redis `GEOSEARCH`.
- NB3: Added a matplotlib bar chart of hourly demand (requested vs sold).
- NB3: Added an N+1-query note with `compute_dynamic_price_batch`, a single-query
  version that preserves identical forecasting semantics.
- NB3: Added a short EWMA "next step" note after the SMA forecast.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
