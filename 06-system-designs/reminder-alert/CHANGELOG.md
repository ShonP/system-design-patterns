# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Reminder Alert` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-20 (review + expansion)
- Significantly expanded all three notebooks with runnable code, richer
  beginner-friendly explanations, and a clear bad → best progression:
  - **01**: back-of-envelope math as code; naive `thread + sleep` demo
    motivating the architecture; richer "why these boxes" commentary.
  - **02**: full in-memory `ReminderService` with schedule / cancel /
    reschedule / get / list; idempotency key handling; timezone-aware
    scheduling with a worked DST example (23-hour gap); DST-safe
    recurring reminders (daily / weekly / monthly).
  - **03**: four scheduler implementations
    (thread-per-reminder → polling loop → heapq min-heap → hashed time
    wheel with rotation counter); retry with exponential backoff +
    dead-letter queue; at-least-once + idempotent receiver demo;
    sharding / hot-ring topology notes.
- All notebooks executed end-to-end with `jupyter nbconvert --execute`
  and verified error-free.
