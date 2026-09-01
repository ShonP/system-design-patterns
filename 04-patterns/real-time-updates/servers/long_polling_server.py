from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import asyncio

app = FastAPI()

messages: list[dict] = []

# Every in-flight long poll registers an asyncio.Event here. Both the poll
# handler and the publisher are `async def`, so they run on the SAME event
# loop thread -- that is what makes this safe. If `post_message` were a plain
# `def`, FastAPI would run it in a worker thread and (a) `event.set()` would
# be called cross-thread on a loop-owned Event, and (b) a message published
# between "no new messages" and "register my event" would be lost, parking
# the client for the full timeout. Both are classic long-polling bugs.
waiting_clients: list[asyncio.Event] = []
new_message_events: dict[asyncio.Event, list] = {}

LONG_POLL_TIMEOUT = 30

class Message(BaseModel):
    user: str = "anonymous"
    text: str

@app.get("/messages/poll")
async def long_poll_messages(since: float = 0, max_wait: float | None = None) -> dict:
    # `max_wait` lets a demo shorten the *server* timeout. Keeping the server
    # timeout below the client's HTTP timeout is the rule you actually want:
    # the server then answers with a tidy `{"timeout": true}` instead of the
    # client aborting mid-request and orphaning the held connection.
    wait_for = LONG_POLL_TIMEOUT if max_wait is None else max(0.1, min(max_wait, LONG_POLL_TIMEOUT))

    # No `await` between the read and the registration below, so nothing can
    # be published in the gap. This is the whole trick.
    new_messages = [msg for msg in messages if msg["timestamp"] > since]
    if new_messages:
        return {
            "messages": new_messages,
            "server_time": datetime.now().timestamp(),
            "timeout": False,
            "waited": 0.0,
        }

    event = asyncio.Event()
    waiting_clients.append(event)
    new_message_events[event] = []

    started = datetime.now().timestamp()
    try:
        await asyncio.wait_for(event.wait(), timeout=wait_for)
        return {
            "messages": new_message_events[event],
            "server_time": datetime.now().timestamp(),
            "timeout": False,
            "waited": datetime.now().timestamp() - started,
        }
    except asyncio.TimeoutError:
        return {
            "messages": [],
            "server_time": datetime.now().timestamp(),
            "timeout": True,
            "waited": datetime.now().timestamp() - started,
        }
    finally:
        if event in waiting_clients:
            waiting_clients.remove(event)
        new_message_events.pop(event, None)

@app.post("/messages", status_code=201)
async def post_message(msg: Message) -> dict:
    message = {
        "id": len(messages) + 1,
        "user": msg.user,
        "text": msg.text,
        "timestamp": datetime.now().timestamp()
    }

    messages.append(message)

    notified = len(waiting_clients)
    for event in waiting_clients:
        new_message_events[event].append(message)
        event.set()

    print(f"📨 New message from {message['user']}: {message['text']}")
    print(f"   Notified {notified} waiting client(s)")
    return message

@app.get("/stats")
async def stats() -> dict:
    return {"waiting_clients": len(waiting_clients), "total_messages": len(messages)}

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Long Polling Server on port 5002")
    print(f"   Timeout: {LONG_POLL_TIMEOUT} seconds (override per request with ?max_wait=)")
    uvicorn.run(app, host="0.0.0.0", port=5002, log_level="warning")
