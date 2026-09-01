# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20
- Lab 1: **fixed a latent crash in `book_multiple_seats`.** It passed
  `tickets[0][0]` as the booking's `event_id`, but column 0 of that query is the
  *ticket* id. When the first available ticket happened to have id <= 5 the booking
  was silently written against the wrong event; when it had a larger id (which the
  randomised seed data makes likely) the insert died on the `events` foreign key.
  Now selects `event_id` explicitly, asserts all seats belong to one event, and the
  demo cross-checks `booking.event_id` against its tickets.
- Lab 1: the cleanup cell reset *every* sold-and-unlinked ticket for event 1, which
  silently wiped the 25 seed 'sold' tickets and changed the dataset for later
  notebooks. It now resets only the tickets the notebook touched and verifies the
  seed survived.
- Lab 1: the pessimistic-vs-optimistic benchmark reported "Nx faster" without saying
  that the gap comes entirely from the artificial 0.05s sleep held inside the
  transaction. Added the honest framing, plus the cost of optimistic (retry storms).
- Lab 2: the no-queue flash sale printed "in production this would crash the server"
  while actually demonstrating `FOR UPDATE SKIP LOCKED` working perfectly for all 50
  users. Replaced with a capacity calculation driven by the *measured* transaction
  time — Little's Law against the container's real `max_connections` — and an explicit
  note about what a 50-thread localhost test does not prove.
- Lab 3: `extend_reservation` and `cancel_booking` did GET-then-EXPIRE / GET-then-DEL,
  a check-then-act race that can extend or delete a lock another user has just
  acquired. Both now use compare-and-set Lua scripts, with a new section explaining
  the window and a demo proving a non-owner can neither release nor extend.
- Lab 3: the end-to-end simulation used f-strings with nested same-type quotes
  (PEP 701), which only parse on Python 3.12+ while `pyproject.toml` declares
  `requires-python = ">=3.10"`. Replaced with lookup tables.
- Lab 3: `simulate_payment` succeeded randomly 90% of the time, so the "happy path"
  demos silently taught a different lesson on ~10% of runs. Payment outcome is now an
  explicit parameter.
- Hygiene: all four notebooks had `kernelspec` `"Python 3"` instead of
  `"Python 3 (.venv)"`. Fixed, and bumped to nbformat 4.5 with cell ids.
- README: added Functional / Non-Functional requirements, a capacity estimate (the
  167k attempts/sec -> 33k connections figure that justifies the waiting queue, and
  the 2 GB hot seat-map working set that justifies the cache), and an explicit
  "where does a hold live" section stating the durability cost of keeping holds in
  Redis rather than only its benefits.


## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
