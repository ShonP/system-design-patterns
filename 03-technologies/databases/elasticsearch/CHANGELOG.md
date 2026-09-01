# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: the lab could not be installed at all. `pyproject.toml` declared `name = "elasticsearch"` while depending on the `elasticsearch` package, so `uv sync` aborted with *"your project depends on itself at an incompatible version"*. Renamed the project to `elasticsearch-lab`.
- **Fix**: the dependency was unpinned, so a fresh resolve installed client 9.x against the 8.13 server in `docker-compose.yml`. Pinned to `>=8.13,<9` to match the server.
- **Fix**: notebook 1's `search_after` demo tiebroke on `_id`, which Elasticsearch 8 rejects (*"Fielddata access on the _id field is disallowed"*). Now tiebreaks on `_seq_no`, with a note explaining why.
- **Fix**: notebook 4 registered an index template for `logs-*` at priority 100, colliding with Elasticsearch's built-in `logs` template and failing with *"multiple index templates may not match during index creation"*. Moved the demo to an `applogs-*` namespace and explained the clash.
- All 4 notebooks now execute end-to-end.

## 2026-04-19
- **NB1**: Added `match` vs `term` section (most common beginner trap) with runnable examples.
- **NB1**: Added `search_after` deep-pagination section demonstrating cursor-based paging past the 10k-result window.
- **NB2**: Added synonym analyzer example (tv/television, laptop/notebook computer, phone aliases).
- **NB3**: Added `cardinality` (HyperLogLog++) and `percentiles` aggregation examples.
- **NB4**: Fixed broken `_shard` terms aggregation — replaced with a working `_cat/shards` distribution view.
- **NB4**: Added **Aliases** section with an end-to-end zero-downtime reindex + atomic alias swap.
- **NB4**: Added **Index Templates** section (component templates + index templates for `logs-*`).
- **NB4**: Added **Index Lifecycle Management (ILM)** section with a hot/warm/cold/delete policy.
- **NB4**: Updated cleanup to also remove new aliases, templates, and ILM policy.
- **README**: Updated notebook table and concept lists to reflect the new topics.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
