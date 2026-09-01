# Chat server (support code)

This is **not** a lab — it is the WebSocket chat backend used by the WhatsApp
lab's notebooks. It is started for you by the lab's `docker-compose.yml`:

```bash
cd ..                 # 06-system-designs/whatsapp
docker compose up -d --build --wait
```

| File | Role |
|------|------|
| `chat_server.py` | WebSocket server: connection registry, message routing, delivery receipts |
| `Dockerfile` | Image built by the lab's compose file |
| `pyproject.toml` | Dependencies for this image only — the notebooks use the lab's own `.venv` |

Read `chat_server.py` to see how the notebooks' claims about connection state,
fan-out, and at-least-once delivery are implemented on the server side.
