"""
WhatsApp-style Chat Server
===========================
A minimal WebSocket chat server that demonstrates the core concepts
of a messaging system: connection management, message routing,
persistence, pub/sub fan-out, presence tracking, and read receipts.

This server is for EDUCATIONAL purposes — it is intentionally simple
so you can follow along in the Jupyter notebooks.
"""

import asyncio
import json
import os
import time
from datetime import datetime, timezone

import psycopg2
import psycopg2.extras
import redis
import websockets

# ---------------------------------------------------------------------------
# Configuration (comes from environment variables set in docker-compose)
# ---------------------------------------------------------------------------
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.getenv("DB_NAME", "whatsapp_demo"),
    "user": os.getenv("DB_USER", "demo"),
    "password": os.getenv("DB_PASSWORD", "demo"),
}

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

WS_HOST = "0.0.0.0"
WS_PORT = 8765

# ---------------------------------------------------------------------------
# Global state — in a real system this would be distributed
# ---------------------------------------------------------------------------
# Maps user_id -> set of websocket connections (a user may have many devices)
connections: dict[int, set] = {}

# Redis client used by the main thread (pub/sub runs in its own thread)
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------
def get_db():
    """Return a new database connection."""
    return psycopg2.connect(**DB_CONFIG)


def db_fetch_one(query, params=None):
    conn = get_db()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return cur.fetchone()
    finally:
        conn.close()


def db_fetch_all(query, params=None):
    conn = get_db()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return cur.fetchall()
    finally:
        conn.close()


def db_execute(query, params=None):
    conn = get_db()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            conn.commit()
            try:
                return cur.fetchone()
            except psycopg2.ProgrammingError:
                return None
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Presence helpers (Redis-based)
# ---------------------------------------------------------------------------
def set_online(user_id: int):
    """Mark user as online with a TTL (acts as a heartbeat lease)."""
    redis_client.set(f"presence:{user_id}", "online", ex=60)


def set_offline(user_id: int):
    """Store the disconnect timestamp and remove the online key."""
    redis_client.delete(f"presence:{user_id}")
    redis_client.set(
        f"last_seen:{user_id}",
        datetime.now(timezone.utc).isoformat(),
    )


def get_presence(user_id: int) -> dict:
    """Return the presence status for a user."""
    if redis_client.get(f"presence:{user_id}"):
        return {"user_id": user_id, "status": "online"}
    last_seen = redis_client.get(f"last_seen:{user_id}")
    return {"user_id": user_id, "status": "offline", "last_seen": last_seen}


# ---------------------------------------------------------------------------
# Message helpers
# ---------------------------------------------------------------------------
def next_sequence(chat_id: int) -> int:
    """Atomically increment and return the next sequence number for a chat."""
    row = db_execute(
        "UPDATE chat_sequences SET last_sequence = last_sequence + 1 "
        "WHERE chat_id = %s RETURNING last_sequence",
        (chat_id,),
    )
    return row["last_sequence"] if row else 1


def store_message(chat_id: int, sender_id: int, content: str, encrypted: str = None):
    """Persist a message and create inbox entries for every recipient."""
    seq = next_sequence(chat_id)
    msg = db_execute(
        "INSERT INTO messages (chat_id, sender_id, content, encrypted_content, sequence_number) "
        "VALUES (%s, %s, %s, %s, %s) RETURNING id, server_timestamp",
        (chat_id, sender_id, content, encrypted, seq),
    )
    msg_id = msg["id"]
    ts = msg["server_timestamp"].isoformat()

    # Create inbox entries for every participant except the sender
    participants = db_fetch_all(
        "SELECT user_id FROM chat_participants WHERE chat_id = %s AND user_id != %s",
        (chat_id, sender_id),
    )
    conn = get_db()
    try:
        with conn.cursor() as cur:
            for p in participants:
                cur.execute(
                    "INSERT INTO inbox (user_id, message_id) VALUES (%s, %s)",
                    (p["user_id"], msg_id),
                )
        conn.commit()
    finally:
        conn.close()

    return {
        "message_id": msg_id,
        "chat_id": chat_id,
        "sender_id": sender_id,
        "content": content,
        "sequence_number": seq,
        "timestamp": ts,
    }


# ---------------------------------------------------------------------------
# WebSocket message handlers
# ---------------------------------------------------------------------------
async def send_json(ws, data: dict):
    await ws.send(json.dumps(data, default=str))


async def handle_send_message(ws, user_id: int, payload: dict):
    """Handle a client sending a message."""
    chat_id = payload["chat_id"]
    content = payload.get("content", "")
    encrypted = payload.get("encrypted_content")

    # 1. Store in Postgres (durable)
    msg = store_message(chat_id, user_id, content, encrypted)

    # 2. ACK the sender
    await send_json(ws, {"type": "ack", "message_id": msg["message_id"], "status": "stored"})

    # 3. Publish to Redis pub/sub for real-time delivery
    participants = db_fetch_all(
        "SELECT user_id FROM chat_participants WHERE chat_id = %s AND user_id != %s",
        (chat_id, user_id),
    )
    event = json.dumps({"type": "new_message", **msg}, default=str)
    for p in participants:
        redis_client.publish(f"user:{p['user_id']}", event)


async def handle_ack(ws, user_id: int, payload: dict):
    """Client acknowledges receiving a message — remove from inbox."""
    message_id = payload["message_id"]
    db_execute(
        "UPDATE inbox SET status = 'delivered', delivered_at = NOW() "
        "WHERE user_id = %s AND message_id = %s AND status = 'pending'",
        (user_id, message_id),
    )
    await send_json(ws, {"type": "ack_ok", "message_id": message_id})


async def handle_read(ws, user_id: int, payload: dict):
    """Client marks a message as read — update inbox and notify sender."""
    message_id = payload["message_id"]
    db_execute(
        "UPDATE inbox SET status = 'read', read_at = NOW() "
        "WHERE user_id = %s AND message_id = %s",
        (user_id, message_id),
    )
    # Notify the original sender via pub/sub
    msg = db_fetch_one("SELECT sender_id, chat_id FROM messages WHERE id = %s", (message_id,))
    if msg:
        event = json.dumps({
            "type": "read_receipt",
            "message_id": message_id,
            "reader_id": user_id,
            "chat_id": msg["chat_id"],
        })
        redis_client.publish(f"user:{msg['sender_id']}", event)

    await send_json(ws, {"type": "read_ok", "message_id": message_id})


async def handle_get_presence(ws, user_id: int, payload: dict):
    target_id = payload["user_id"]
    info = get_presence(target_id)
    await send_json(ws, {"type": "presence", **info})


async def handle_create_chat(ws, user_id: int, payload: dict):
    participant_ids = payload["participants"]  # list of user_ids
    name = payload.get("name")
    is_group = len(participant_ids) > 2 or name is not None

    chat = db_execute(
        "INSERT INTO chats (name, is_group, created_by) VALUES (%s, %s, %s) RETURNING id",
        (name, is_group, user_id),
    )
    chat_id = chat["id"]

    # Ensure the creator is a participant
    all_ids = set(participant_ids) | {user_id}
    conn = get_db()
    try:
        with conn.cursor() as cur:
            for uid in all_ids:
                role = "admin" if uid == user_id else "member"
                cur.execute(
                    "INSERT INTO chat_participants (chat_id, user_id, role) VALUES (%s, %s, %s)",
                    (chat_id, uid, role),
                )
            cur.execute(
                "INSERT INTO chat_sequences (chat_id, last_sequence) VALUES (%s, 0)",
                (chat_id,),
            )
        conn.commit()
    finally:
        conn.close()

    await send_json(ws, {"type": "chat_created", "chat_id": chat_id})


async def handle_sync(ws, user_id: int, payload: dict):
    """Deliver all pending inbox messages to a reconnecting client."""
    rows = db_fetch_all(
        "SELECT m.id AS message_id, m.chat_id, m.sender_id, m.content, "
        "m.sequence_number, m.server_timestamp "
        "FROM inbox i JOIN messages m ON i.message_id = m.id "
        "WHERE i.user_id = %s AND i.status = 'pending' "
        "ORDER BY m.server_timestamp",
        (user_id,),
    )
    for r in rows:
        await send_json(ws, {
            "type": "new_message",
            "message_id": r["message_id"],
            "chat_id": r["chat_id"],
            "sender_id": r["sender_id"],
            "content": r["content"],
            "sequence_number": r["sequence_number"],
            "timestamp": r["server_timestamp"].isoformat() if r["server_timestamp"] else None,
        })
    await send_json(ws, {"type": "sync_complete", "count": len(rows)})


HANDLERS = {
    "send_message": handle_send_message,
    "ack": handle_ack,
    "read": handle_read,
    "get_presence": handle_get_presence,
    "create_chat": handle_create_chat,
    "sync": handle_sync,
}


# ---------------------------------------------------------------------------
# Redis pub/sub listener — forwards messages to local WebSocket connections
# ---------------------------------------------------------------------------
async def redis_subscriber(user_id: int, ws):
    """Subscribe to the user's Redis channel and forward messages."""
    pubsub = redis_client.pubsub()
    channel = f"user:{user_id}"
    pubsub.subscribe(channel)
    try:
        while True:
            msg = pubsub.get_message(ignore_subscribe_messages=True, timeout=0.5)
            if msg and msg["type"] == "message":
                await ws.send(msg["data"])
            await asyncio.sleep(0.05)
    except (websockets.exceptions.ConnectionClosed, asyncio.CancelledError):
        pass
    finally:
        pubsub.unsubscribe(channel)
        pubsub.close()


# ---------------------------------------------------------------------------
# Main connection handler
# ---------------------------------------------------------------------------
async def handler(ws):
    """Handle a single WebSocket connection lifecycle."""
    user_id = None
    sub_task = None

    try:
        # First message must be an auth/connect message
        raw = await ws.recv()
        data = json.loads(raw)
        if data.get("type") != "connect":
            await send_json(ws, {"type": "error", "message": "First message must be type 'connect'"})
            return

        user_id = int(data["user_id"])
        connections.setdefault(user_id, set()).add(ws)
        set_online(user_id)

        # Start Redis subscription in the background
        sub_task = asyncio.create_task(redis_subscriber(user_id, ws))

        await send_json(ws, {"type": "connected", "user_id": user_id})
        print(f"[+] User {user_id} connected  (total ws: {sum(len(v) for v in connections.values())})")

        # Main message loop
        async for raw in ws:
            try:
                data = json.loads(raw)
                msg_type = data.get("type")
                handler_fn = HANDLERS.get(msg_type)
                if handler_fn:
                    await handler_fn(ws, user_id, data)
                elif msg_type == "heartbeat":
                    set_online(user_id)
                    await send_json(ws, {"type": "heartbeat_ack"})
                else:
                    await send_json(ws, {"type": "error", "message": f"Unknown type: {msg_type}"})
            except Exception as e:
                await send_json(ws, {"type": "error", "message": str(e)})

    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        if user_id is not None:
            connections.get(user_id, set()).discard(ws)
            if not connections.get(user_id):
                connections.pop(user_id, None)
                set_offline(user_id)
            print(f"[-] User {user_id} disconnected")
        if sub_task:
            sub_task.cancel()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
async def main():
    print(f"🚀 WhatsApp Chat Server starting on ws://{WS_HOST}:{WS_PORT}")
    async with websockets.serve(handler, WS_HOST, WS_PORT):
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    asyncio.run(main())
