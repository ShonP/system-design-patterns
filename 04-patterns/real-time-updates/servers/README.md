# Server files for Real-time Updates notebooks

All servers use FastAPI/Pydantic for clean, typed implementations.

**You do not need to start these by hand.** Each notebook calls
`lab_servers.ensure_server(<port>)`, which launches the right script as a
background process using the notebook's own interpreter and terminates it via
an `atexit` hook when the kernel exits. A port that is already listening is
left alone, so a server you started yourself always wins. Call
`lab_servers.stop_all()` to shut down everything the notebook started.

## Running Servers by hand (optional — useful for watching the logs)

```bash
# Activate the virtual environment first
source ../.venv/bin/activate

# Then run any server:
python simple_polling_server.py  # port 5001
python long_polling_server.py    # port 5002
python sse_server.py             # port 5003
python websocket_server.py       # port 5004
python webhook_server.py         # port 5005
```

## Server Overview

| Server | Port | Pattern |
|--------|------|---------|
| simple_polling_server.py | 5001 | Basic request/response polling |
| long_polling_server.py | 5002 | Held requests until data available (`?max_wait=` shortens the hold) |
| sse_server.py | 5003 | Server-Sent Events with Last-Event-ID, `retry:` and a tunable `?heartbeat=` |
| websocket_server.py | 5004 | Bidirectional WebSocket chat, token auth on the join frame (close 1008) |
| webhook_server.py | 5005 | Vendor-style delivery: HMAC over `<timestamp>.<body>` + retries |

## 🔍 Visualization Tools

Start Redis and RedisInsight with Docker:

```bash
cd ..
docker compose up -d
```

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **Setup**: Add database with Host = `redis`, Port = `6379` (the compose service name)
- **Use for**: Watch Pub/Sub messages in real-time (Notebook 7)
