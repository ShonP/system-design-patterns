# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Notebook 1: Added a **bad → best progression** section contrasting HTTP polling vs WebSocket-only vs WebSocket+inbox+pub/sub, with back-of-envelope math showing polling does ~432× more work per delivered message.
- Notebook 2: Added **Section 7 — Typing Indicators** (pure Redis pub/sub, no DB writes) with a runnable ephemeral demo.
- Notebook 2: Added **Section 8 — Media Handling** covering object-storage + signed-URL uploads, schema additions, and E2E-encrypted media considerations.
- Added `tabulate` dependency to `pyproject.toml` so Notebook 3 (Group Messaging) runs without `ModuleNotFoundError`.
- Verified all 4 notebooks execute end-to-end with zero errors against the Docker stack.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
