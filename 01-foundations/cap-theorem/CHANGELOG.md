# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- Corrected the setup path in the README and all 3 notebooks (`cd core-concepts/cap-theorem` → `01-foundations/cap-theorem`).
- Normalised the notebook kernel to the lab's own `.venv`.
- All 3 notebooks executed end-to-end against the docker-compose stack. Note the standby publishes on host port **55433**; if something else on your machine owns that port the stack will not start (`python tools/check_ports.py` will tell you what is holding it).
