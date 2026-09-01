# Google Calendar

> Part of `06-system-designs/`. Runnable notebooks + references.

## Overview

Calendar: events, reminders, recurring events, sharing.

## Concepts covered

- Event vs occurrence; store the RRULE, expand on read
- Recurring rules (RFC 5545 iCalendar RRULE via `python-dateutil`)
- Timezone handling (UTC in storage + IANA zone for display, DST-jump detection)
- **Recurrence × DST**: why expanding an RRULE in UTC silently slides a 9am standup to
  10am, and how expanding in local wall time fixes it
- Nonexistent and ambiguous wall-clock times (`fold`), and picking an explicit policy
- Capacity estimation: read:write ratio, storage, and the 36× reminder spike
- Invitations & RSVP, meeting rooms as resources
- Sharing / ACLs
- Single-occurrence overrides and cancellations (`event_exceptions` delta table)
- Free/busy availability: bad minute-mask → best sweep-line interval merge

## Setup

```bash
cd 06-system-designs/google-calendar
uv sync
```

Select the `.venv` kernel in VS Code (top-right). If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.

## Notebooks

- [`notebooks/01_requirements_and_architecture.ipynb`](./notebooks/01_requirements_and_architecture.ipynb) — Requirements & Architecture
- [`notebooks/02_data_and_api.ipynb`](./notebooks/02_data_and_api.ipynb) — Data Model & APIs
- [`notebooks/03_deep_dive.ipynb`](./notebooks/03_deep_dive.ipynb) — Deep Dive (runnable code)

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
