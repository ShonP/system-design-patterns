from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import threading

app = FastAPI()

messages: list[dict] = []
message_lock = threading.Lock()

class Message(BaseModel):
    user: str = "anonymous"
    text: str

class MessageResponse(BaseModel):
    id: int
    user: str
    text: str
    timestamp: float

@app.get("/messages")
def get_messages(since: float = 0) -> dict:
    with message_lock:
        new_messages = [msg for msg in messages if msg["timestamp"] > since]
    return {"messages": new_messages, "server_time": datetime.now().timestamp()}

@app.post("/messages", status_code=201)
def post_message(msg: Message) -> MessageResponse:
    message = {
        "id": len(messages) + 1,
        "user": msg.user,
        "text": msg.text,
        "timestamp": datetime.now().timestamp()
    }
    with message_lock:
        messages.append(message)
    print(f"📨 New message from {message['user']}: {message['text']}")
    return MessageResponse(**message)

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Simple Polling Server on port 5001")
    uvicorn.run(app, host="0.0.0.0", port=5001, log_level="warning")
