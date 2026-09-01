# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: added the missing `numpy` dependency to `pyproject.toml`. Notebook 4 imports it, so a fresh `uv sync` produced a lab whose last notebook died on `ModuleNotFoundError`.
- **Fix**: notebook 4 was pinned to a Jupyter kernel named `consistent-hashing` that is not registered anywhere, so opening it raised `NoSuchKernel`. All notebooks now use the lab's own `.venv`.
- All 4 notebooks executed end-to-end to verify they run cleanly.
