# Server files for Real-time Updates notebooks

All servers use FastAPI/Pydantic for clean, typed implementations.

## Running Servers

```bash
# Activate the virtual environment first
source ../.venv/bin/activate

# Then run any server:
python simple_polling_server.py  # port 5001
python long_polling_server.py    # port 5002
python sse_server.py             # port 5003
python websocket_server.py       # port 5004
```

## Server Overview

| Server | Port | Pattern |
|--------|------|---------|
| simple_polling_server.py | 5001 | Basic request/response polling |
| long_polling_server.py | 5002 | Held requests until data available |
| sse_server.py | 5003 | Server-Sent Events with Last-Event-ID |
| websocket_server.py | 5004 | Bidirectional WebSocket chat |

## 🔍 Visualization Tools

Start Redis and RedisInsight with Docker:

```bash
cd ..
docker-compose up -d
```

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **Setup**: Add database with Host = `host.docker.internal`, Port = `6379`
- **Use for**: Watch Pub/Sub messages in real-time (Notebook 7)
