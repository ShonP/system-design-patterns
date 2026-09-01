# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- Corrected the setup path in the README and notebooks (`cd core-concepts/api-design` pointed at a directory that no longer exists after the repo restructure; it is now `01-foundations/api-design`).
- Normalised the notebook kernel to the lab's own `.venv` and dropped the global `ipykernel install` step, so the notebooks open without a `NoSuchKernel` error.
- All 4 notebooks executed end-to-end against the docker-compose stack to verify they run cleanly.
