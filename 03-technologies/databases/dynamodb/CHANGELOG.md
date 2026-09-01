# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: notebooks 2, 3 and 4 wrote float literals into items, which boto3 rejects outright (*"Float types are not supported. Use Decimal types instead."*). All money-like values now use `Decimal(str(x))`, with a note on why `Decimal(29.99)` would be wrong too.
- All 5 notebooks now execute end-to-end against DynamoDB Local.

## 2026-04-19
- Added notebook 5 `05_capacity_ttl_transactions_and_hot_partitions.ipynb` covering on-demand vs provisioned capacity, TTL, conditional writes / optimistic locking, `TransactWriteItems`, hot-partition write sharding, and DAX — structured as bad→best progressions.
- README: added new "Capacity Modes" and "Hot Partitions & Write Sharding" sections, expanded real-world examples table (sessions/TTL, shopping cart/optimistic locking, bank transfer/transactions, trending feed/sharding), and aligned setup instructions with the repo's `.venv` kernel convention.
- Fixed stale `cd 03-technologies/databases/dynamodb` paths in README and notebook setup cells to the actual lab path `cd 03-technologies/databases/dynamodb`.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
