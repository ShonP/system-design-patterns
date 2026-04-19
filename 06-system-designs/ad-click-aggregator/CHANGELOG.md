# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Swapped the broken `bitnami/kafka:3.7` image (removed from Docker Hub) for
  the maintained `confluentinc/cp-kafka:7.6.0` image. All listener names
  and external port (`9094`) are preserved so notebooks run unchanged.
- **Notebook 1** — added a new "Hot Shard Mitigation" section that simulates
  a viral ad (80 % of traffic on one `ad_id`) and shows how appending a
  random suffix to the partition key rebalances the load.
- **Notebook 2** — added a "Sliding Windows" section (SQL window-function
  and pure-Python implementations) so the notebook finally delivers on its
  title, plus a "Reconciliation & Lambda Architecture" section that injects
  a streaming drift and repairs it from the raw events table.
- Verified every notebook executes cleanly end-to-end via
  `jupyter nbconvert --execute`.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
