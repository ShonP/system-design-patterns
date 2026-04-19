# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Saga` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_introduction.ipynb, 02_choreography_vs_orchestration.ipynb, 03_compensation_on_failure.ipynb.

## 2026-04-19
- QA pass: rewrote all three notebooks with a clearer bad→good progression and more beginner explanations.
  - `01_introduction.ipynb`: added naive "no compensation" baseline, e-commerce checkout framing, vocabulary section (local/compensating transactions, backward/forward recovery, pivot).
  - `02_choreography_vs_orchestration.ipynb`: class-based orchestrator, richer event-bus choreography with failure + compensation, side-by-side trade-off table, real-world tool mapping.
  - `03_compensation_on_failure.ipynb`: idempotency, retry-before-compensate with exponential backoff, semantic compensation (apology email), pivot transaction / forward-only recovery, production checklist.
- All notebooks executed end-to-end with `jupyter nbconvert --execute`.

## 2026-04-19
- Added `04_saga_log_and_recovery.ipynb`: shows why in-memory sagas lose state on crash, builds a SQLite-backed `DurableSaga` runner that persists `(saga_id, step, status)`, demonstrates crash-then-resume for both the forward path and mid-compensation, and maps the pattern to real engines (Temporal, Step Functions, Camunda, Conductor, Kafka+outbox).
- Executed the new notebook end-to-end with `jupyter nbconvert --execute` and updated `README.md` accordingly.
