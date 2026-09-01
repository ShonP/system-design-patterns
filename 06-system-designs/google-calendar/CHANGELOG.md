# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (review pass)
- NB1 had **zero code cells**. Added two: a capacity-estimation cell (traffic, storage,
  and the reminder fan-out peak) and a cell that quantifies "store the rule, not the
  occurrences" — materializing occurrences costs ~376x the rows.
- NB1: fixed the sizing arithmetic. "1 B users × ~20 events/week ⇒ ~1 T events over 10
  years" was off by an order of magnitude (that input gives ~10 T). The stated
  "read:write ≈ 100:1" was also not reachable from any plausible input; the notebook now
  derives ~28:1 from explicit assumptions. The asserted "~100k reminders/second" peak is
  now computed (~833k/s, 36x the average) instead of asserted.
- NB3: added the deep dive this lab was missing — **recurrence across a DST boundary**.
  A daily 9am LA standup expanded from a UTC anchor drifts to 10am after 8 Mar 2026;
  expanding over naive local times and attaching the zone per occurrence keeps 9am. Both
  behaviours are asserted.
- NB3: added detection of **nonexistent** (spring-forward gap) and **ambiguous**
  (fall-back, happens twice) wall-clock times, with explicit policies for each, plus the
  tzdata-versioning and cross-timezone-invitee consequences.
- NB2: qualified the "UTC is the source of truth" rule of thumb, which is correct for
  one-off events and wrong for recurring ones.

## 2026-04-18
- Scaffolded `Google Calendar` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-20 (review & improvements)
- Added `python-dateutil` dependency for real RFC 5545 RRULE support.
- Notebook 1: expanded requirements (invites, rooms, availability, sharing, reminders),
  clearer architecture diagram, explicit read:write ratio, clearer "two core ideas" section.
- Notebook 2:
  - Added bad → best progression for timezone handling with a live DST-jump detection demo.
  - Strengthened Pydantic models with `field_validator`/`model_validator` for UTC-only,
    IANA-zone, and `ends_at > starts_at` invariants, plus failing cases that prove the validators fire.
  - Added `Invitation`, `Room`, `Reminder` models; noted idempotency-key convention.
- Notebook 3:
  - Kept toy DAILY expander; added production-grade `dateutil.rrule` example.
  - Cleaned up single-occurrence override/cancel demo (keyed on `original_start`).
  - Added **free/busy** deep dive: naive minute-mask vs sweep-line interval merge,
    plus 200-iteration randomized oracle cross-check.
  - Added "real-world caveats" (all-day events, EXDATE/RDATE, "this and future" edits,
    working hours, resources, delegation, reminder scale).
- All notebooks executed end-to-end — outputs now persisted in the `.ipynb` files.
