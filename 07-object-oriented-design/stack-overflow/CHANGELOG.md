# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Stack Overflow` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-18
- Added `pyproject.toml` and notebooks: 01_class_design.ipynb, 02_implementation.ipynb.

## 2026-04-20
- Expanded `01_class_design.ipynb`: clarifying questions, actors/use-cases, entities, UML, SOLID check.
- Rewrote `02_implementation.ipynb` as a Bad → Good → Best progression with a self-check cell.
- Added `03_extensions.ipynb`: tags + search (inverted index), badges via observer pattern, moderation (close/reopen/delete), thread-safe voting (race reproduction + lock fix), and pluggable reputation rules (strategy pattern).
- Verified all notebooks execute cleanly with `uv run jupyter nbconvert --execute`.
- Updated README concept list and notebook index.

## 2026-08-20
- QA pass: every notebook re-executed end to end and verified clean.
- `01_class_design.ipynb` had **zero code cells**. Added the design as a runnable
  **skeleton** — `VoteType` / `QuestionStatus` enums, an abstract `Post`,
  `Question` / `Answer` / `Comment` / `Badge` — plus a demo and an assertion cell
  that restates every line of the class diagram as a checkable property
  (abstract base, is-a, has-many, symmetric back-references, 0..1 accepted
  answer, one-vote-per-user by construction).
  The skeleton also replaces the `isinstance(post, Answer)` reputation check with
  a polymorphic `rep_per_upvote`, and the notebook now points that out as a smell
  to watch for in notebook 2.
- `03_extensions.ipynb`:
  - The concurrency demo printed `rep = 80` for both the unsafe and safe versions,
    so the bug was invisible. It now states the invariant
    (`rep == 10 × distinct voters`) and reports the violation explicitly.
  - `ReputationPolicy.on_accept()` was declared abstract but never called, and the
    accept bonus stayed hard-coded inside `Question.accept` — so swapping in
    `ClassroomPolicy` still paid the classic +15. Reputation is now entirely in the
    policy, `accept_v3()` prices acceptance through it, and the notebook explains
    why a half-wired strategy is worse than none.
- Notebook hygiene: kernelspec normalised to `Python 3 (.venv)`, saved outputs stripped.
