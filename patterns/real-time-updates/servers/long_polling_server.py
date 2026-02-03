from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import threading
import asyncio

app = FastAPI()

messages: list[dict] = []
message_lock = threading.Lock()

waiting_clients: list[asyncio.Event] = []
new_message_events: dict[asyncio.Event, list] = {}
clients_lock = threading.Lock()

LONG_POLL_TIMEOUT = 30

class Message(BaseModel):
    user: str = "anonymous"
    text: str

@app.get("/messages/poll")
async def long_poll_messages(since: float = 0) -> dict:
    with message_lock:
        new_messages = [msg for msg in messages if msg["timestamp"] > since]
    
    if new_messages:
        return {"messages": new_messages, "server_time": datetime.now().timestamp()}
    
    event = asyncio.Event()
    with clients_lock:
        waiting_clients.append(event)
        new_message_events[event] = []
    
    try:
        await asyncio.wait_for(event.wait(), timeout=LONG_POLL_TIMEOUT)
        return {"messages": new_message_events[event], "server_time": datetime.now().timestamp()}
    except asyncio.TimeoutError:
        return {"messages": [], "server_time": datetime.now().timestamp(), "timeout": True}
    finally:
        with clients_lock:
            if event in waiting_clients:
                waiting_clients.remove(event)
            new_message_events.pop(event, None)

@app.post("/messages", status_code=201)
def post_message(msg: Message) -> dict:
    message = {
        "id": len(messages) + 1,
        "user": msg.user,
        "text": msg.text,
        "timestamp": datetime.now().timestamp()
    }
    
    with message_lock:
        messages.append(message)
    
    with clients_lock:
        for event in waiting_clients:
            new_message_events[event].append(message)
            event.set()
    
    print(f"📨 New message from {message['user']}: {message['text']}")
    print(f"   Notified {len(waiting_clients)} waiting client(s)")
    return message

@app.get("/stats")
def stats() -> dict:
    with clients_lock:
        waiting = len(waiting_clients)
    with message_lock:
        total_messages = len(messages)
    return {"waiting_clients": waiting, "total_messages": total_messages}

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Long Polling Server on port 5002")
    print(f"   Timeout: {LONG_POLL_TIMEOUT} seconds")
    uvicorn.run(app, host="0.0.0.0", port=5002, log_level="warning")
