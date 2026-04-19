# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Key Value Store` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Expanded all three notebooks with runnable, bad→best code progressions:
  - **NB1:** added `hash % N` failure demo and a consistent-hashing preview; added
    architecture diagram and a real-world comparison table (Dynamo / Cassandra /
    Riak / Redis Cluster / etcd / Memcached).
  - **NB2:** added silent-data-loss demo, last-write-wins with versions, vector
    clocks with sibling merging, and a toy LSM-tree (WAL + memtable + SSTables).
  - **NB3:** added single-vnode vs 128-vnode load-balance comparison, a runnable
    Merkle-tree diff, and a hinted-handoff + read-repair simulation.
- All 13 code cells execute cleanly via `uv run jupyter nbconvert --execute`.
