# Mini-SIEM (support code)

This is **not** a lab module — it is the mini-SIEM service shared by all three
SC-200 labs. Lab 1 starts it; labs 2 and 3 assume it is already running:

```bash
cd ../01-build-a-siem
docker compose up -d          # serves the SIEM API on http://localhost:8000
```

| File | Role |
|------|------|
| `server.py` | The SIEM API: log ingestion, detection rules, alerts, incidents, entity pivots |
| `log_generator.py` | Seeds realistic sign-in / endpoint / email / network logs, including the attack chain the labs investigate |
| `Dockerfile` | Image for the SIEM service |
| `Dockerfile.generator` | Image for the one-shot log seeder (it exits 0 once seeding finishes — that is expected) |
| `pyproject.toml` | Dependencies for these images only — each lab's notebooks use their own `.venv` |

If a notebook fails with `ConnectError` on `localhost:8000`, the SIEM is not
running. Start it as above and confirm with `docker compose ps` that
`sc200-siem` is **healthy**.
