# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: the stack could not start. `DB=postgresql` is not a driver the auto-setup image accepts, so `temporal-server` exited(1) with *"Unsupported driver specified"* and took the worker down with it. Corrected to `postgres12`.
- **Fix**: every notebook that starts a Worker failed with *"Failed validating workflow ..."*. Temporal's sandbox re-imports the module that defines the workflow, which in a notebook is `__main__` -- so the re-import re-ran the cells and blew up on `asyncio.run() cannot be called from a running event loop`. All 25 `Worker(...)` constructions now pass `workflow_runner=UnsandboxedWorkflowRunner()`, with a note explaining why a real worker process should keep the default sandbox.
- **Fix**: three breaks caused by SDK drift on an unpinned `temporalio>=1.7`: `WorkflowAlreadyStartedError` moved to `temporalio.exceptions`; `start_workflow()` no longer accepts multiple positional workflow arguments (must use `args=[...]`); and a query typed `dict[str, object]` cannot be deserialized by the caller (*"Unserializable type during conversion: <class 'object'>"*) -- it now returns a typed `AgentStats` dataclass. Pinned `temporalio>=1.26,<2`.
- **Fix**: notebook 8 had literal `\n` escapes that had been turned into real newlines inside f-strings, leaving two cells with unterminated string literals.
- All 10 notebooks now execute end-to-end against the stack (previously only notebook 1 did).

## 2026-04-19
- Fixed outdated `enterprise-patterns/long-running-jobs-temporal` paths in the README and notebooks 2–4 so they match the current `03-technologies/workflow-engines/temporal` location.
- Fixed the idempotency demo in notebook 2 to catch `WorkflowAlreadyStartedError` (the exception raised by modern `temporalio`) instead of the lower-level `RPCError`.
- Added notebook **`05_queries_heartbeats_testing.ipynb`** covering four production-critical concepts that were missing: **Queries** (reading live workflow state), **Heartbeats** (keeping long activities alive and resumable), **Continue-As-New** (running workflows forever without history bloat), and **Testing** with `WorkflowEnvironment.start_time_skipping()` (unit-test workflows in CI without Docker).

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
