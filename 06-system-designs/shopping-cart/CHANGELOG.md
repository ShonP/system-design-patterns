# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Shopping Cart` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18 (notebooks added)
- Added `pyproject.toml` (Python 3.10+, pydantic).
- Added 3 runnable notebooks:
  - `notebooks/01_requirements_and_architecture.ipynb`
  - `notebooks/02_data_and_api.ipynb`
  - `notebooks/03_deep_dive.ipynb`
- Updated `README.md` with setup + notebook links.

## 2026-04-20 (content upgrade)
- Rewrote all 3 notebooks with explicit **bad → best** progression per repo convention.
- **Notebook 1**: runnable back-of-envelope math (100M DAU → ~30k WPS / ~150k RPS
  peak), Availability > Consistency trade-off, bad-vs-best on denormalized prices.
- **Notebook 2**: naïve dict vs Pydantic models with anti-hoarding caps
  (qty ≤ 10, ≤ 50 items), NoSQL PK/SK design, `/cart/merge` API contract,
  improved idempotency demo with in-flight state + TTL.
- **Notebook 3**: added `Inventory.release()` for clean saga compensation;
  new runnable deep dives for **data hydration with short-TTL product cache**
  and the **idempotent guest→user merge algorithm** with quantity caps.
- All notebooks execute end-to-end under `uv run jupyter nbconvert --execute`.
