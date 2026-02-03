from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from datetime import datetime
from collections import deque
import asyncio
import json

app = FastAPI()

subscribers: list[asyncio.Queue] = []
message_id = 0
MESSAGE_BUFFER_SIZE = 100
message_buffer: deque = deque(maxlen=MESSAGE_BUFFER_SIZE)

class Message(BaseModel):
    user: str = "anonymous"
    text: str

def format_sse(data: dict, event: str | None = None, id: int | None = None) -> str:
    msg = ""
    if id is not None:
        msg += f"id: {id}\n"
    if event:
        msg += f"event: {event}\n"
    msg += f"data: {json.dumps(data)}\n\n"
    return msg

@app.get("/events")
async def events(request: Request):
    last_event_id_str = request.headers.get("Last-Event-ID")
    last_event_id = int(last_event_id_str) if last_event_id_str else 0
    
    async def generate():
        client_queue: asyncio.Queue = asyncio.Queue()
        subscribers.append(client_queue)
        
        if last_event_id:
            print(f"📱 SSE client RECONNECTED with Last-Event-ID: {last_event_id}")
            missed = [msg for msg in message_buffer if msg["id"] > last_event_id]
            if missed:
                print(f"   ↳ Replaying {len(missed)} missed message(s)")
                for msg in missed:
                    yield format_sse(msg, event="message", id=msg["id"])
        else:
            print(f"📱 New SSE client connected (total: {len(subscribers)})")
        
        yield format_sse({"type": "connected", "message": "Welcome!", "recovered_from": last_event_id}, event="connection")
        
        try:
            while True:
                try:
                    message = await asyncio.wait_for(client_queue.get(), timeout=15)
                    yield message
                except asyncio.TimeoutError:
                    yield format_sse({"type": "heartbeat"}, event="heartbeat")
        except asyncio.CancelledError:
            pass
        finally:
            if client_queue in subscribers:
                subscribers.remove(client_queue)
            print(f"📴 SSE client disconnected (remaining: {len(subscribers)})")
    
    return StreamingResponse(generate(), media_type="text/event-stream", headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})

@app.post("/send", status_code=201)
async def send_message(msg: Message) -> dict:
    global message_id
    message_id += 1
    
    message = {"id": message_id, "user": msg.user, "text": msg.text, "timestamp": datetime.now().isoformat()}
    message_buffer.append(message)
    
    sse_message = format_sse(message, event="message", id=message_id)
    for queue in subscribers:
        await queue.put(sse_message)
    
    print(f"📨 Broadcast to {len(subscribers)} client(s): {message['text']} (buffered, total: {len(message_buffer)})")
    return message

@app.get("/stats")
def stats() -> dict:
    return {"connected_clients": len(subscribers), "messages_sent": message_id, "buffer_size": len(message_buffer), "buffer_max_size": MESSAGE_BUFFER_SIZE}

@app.get("/buffer")
def get_buffer() -> dict:
    return {"messages": list(message_buffer), "count": len(message_buffer)}

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting SSE Server on port 5003")
    print(f"   📦 Message buffer size: {MESSAGE_BUFFER_SIZE}")
    uvicorn.run(app, host="0.0.0.0", port=5003, log_level="warning")
