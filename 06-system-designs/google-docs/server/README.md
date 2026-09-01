# Collaborative document server (support code)

This is **not** a lab — it is the backend used by the Google Docs lab's
notebooks. It is started for you by the lab's `docker-compose.yml`:

```bash
cd ..                 # 06-system-designs/google-docs
docker compose up -d --build --wait
```

| File | Role |
|------|------|
| `doc_server.py` | The collaborative editing server the notebooks connect to |
| `Dockerfile` | Image built by the lab's compose file |
| `pyproject.toml` | Dependencies for this image only — the notebooks use the lab's own `.venv` |

Read `doc_server.py` when you want to see how the concurrency-control approach
the notebooks discuss (operational transform / CRDT merge) is actually
implemented server-side, rather than simulated in a notebook cell.
