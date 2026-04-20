# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Added `notebooks/04_reserve_increments_proxy_bidding.ipynb` covering hidden reserve prices, eBay-style bid increment ladders, and proxy (automatic) bidding. The notebook extends the existing `auctions` table with additive `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` migrations — no data loss.
- Fixed a timezone bug in `notebooks/02_auction_lifecycle_management.ipynb` (`place_bid_with_extension`): anti-sniping was silently broken when the Python process and Postgres container ran in different timezones. The time comparison now happens server-side in Postgres using `NOW() - end_date`, so the extension triggers reliably regardless of client tz.
- Fixed hang in `notebooks/03_real_time_bid_notifications.ipynb`: replaced `pubsub.listen()` loops (which block forever between messages and never notice the `duration` timeout) with `pubsub.get_message(timeout=...)` loops that exit cleanly.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
