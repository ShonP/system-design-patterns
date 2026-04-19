# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Fixed `05_dead_letter_queue.ipynb`: DLQ SQL used non-existent columns (`job_id`, `created_at`); now uses `original_job_id` / `moved_at` and persists `job_type` + `payload` as the `dead_letter_queue` table requires.
- Fixed `05_dead_letter_queue.ipynb`: handle UUID / JSONB return types from psycopg2 when building the poison-job lookup.
- Added a **🔧 Setup** cell to every notebook instructing users to `docker compose up -d`, `uv sync`, and pick the lab's `.venv` kernel in VS Code.
- Added a **🌍 Real-world** callout to each notebook (Stripe, Instagram, YouTube, SQS, Shopify) to ground the concepts.
- Added a **📶 Progress Reporting** pattern to `06_advanced_patterns.ipynb` showing how workers write `% done` to Redis for polling clients.
- Normalized notebook cell IDs to satisfy nbformat 5.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
