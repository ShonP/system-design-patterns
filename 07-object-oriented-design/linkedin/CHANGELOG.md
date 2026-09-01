# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Linkedin` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Rewrote `notebooks/01_class_design.ipynb` with a full **bad → best progression**
  covering 5 common LinkedIn modelling mistakes (connections without a request object,
  string statuses, ungarded transitions, nested-loop skill matching, endorsements as a counter).
- Rewrote `notebooks/02_implementation.ipynb` into a 9-step runnable build covering
  `Profile`, `User`, `ConnectionRequest` state machine, `ConnectionService`
  (blocks duplicate pending requests), `Company`/`Job`/`Application` with its own state machine,
  `EndorsementBook`, connection-restricted `Message`/`Inbox`, and a `JobRecommender` that
  combines skill match with an "someone you know works there" bonus.
- Both notebooks verified with `uv run jupyter nbconvert --execute`.
- Updated README concept list to reflect new content.

## 2026-08-20
- QA pass: re-verified every notebook executes end to end with
  `uv run jupyter nbconvert --execute`; normalized the kernelspec to
  `Python 3 (.venv)` and stripped saved outputs.
- Fixed `JobRecommender.score`, which constructed a throwaway `Application` just to compute
  a skill match — burning an application id and implying a submission that never happened.
  `match_score` now lives on `Job` (where the data is); `Application.match_score` delegates.
- Added a "verify the design" cell: terminal-state guards on both state machines, the
  `ConnectionService` duplicate/self-connect rules, skill normalization, endorsement
  dedup + self-endorsement guard, DM gating, and an assertion that recommending creates
  no phantom `Application`.
