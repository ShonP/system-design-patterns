# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- Corrected the setup path in the README and notebook 1 (`cd core-concepts/caching` → `01-foundations/caching`).
- Normalised the notebook kernel to the lab's own `.venv` and dropped the global `ipykernel install` step.
- All 6 notebooks executed end-to-end against the docker-compose stack to verify they run cleanly.
