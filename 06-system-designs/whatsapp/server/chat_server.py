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
    """Mark user as online with a TTL (acts as a heartbeat lease).

    We also stamp `last_seen` on every refresh. That looks redundant while the
    client is alive, but it is what makes "last seen" survive a HARD crash:
    if the phone dies without a clean disconnect, nobody ever calls
    set_offline(), the presence key just expires -- and without this stamp the
    user would show as "offline, last seen: never".
    """
    now = datetime.now(timezone.utc).isoformat()
    pipe = redis_client.pipeline()
    pipe.set(f"presence:{user_id}", "online", ex=60)
    pipe.set(f"last_seen:{user_id}", now)
    pipe.execute()


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
def store_message(chat_id: int, sender_id: int, content: str, encrypted: str = None):
    """Persist a message and create inbox entries for every recipient.

    ALL THREE writes -- bump the sequence, insert the message, fan out the
    inbox rows -- happen in ONE transaction. That matters for two reasons:

    1. Atomicity. A crash halfway through must not leave a message with no
       inbox rows (nobody would ever receive it), nor burn a sequence number
       with no message behind it (every client would report a permanent gap).

    2. Per-chat ORDERING. `UPDATE chat_sequences ... RETURNING` takes a row
       lock on this chat's counter and holds it until COMMIT. So a second
       sender in the same chat blocks until we are done. Sequence order then
       equals commit order equals server_timestamp order -- they can never
       disagree. Allocating the sequence in its own transaction (as an earlier
       version of this server did) lets sender A grab seq=5, sender B grab
       seq=6, and then B commit FIRST -- so a reader ordering by timestamp
       would show message 6 before message 5.

    Note this serialises writes per chat, not globally. Two different chats
    still write concurrently, because they lock different counter rows.
    """
    conn = get_db()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            # 1. Take the per-chat sequence lock and allocate the next number.
            cur.execute(
                "UPDATE chat_sequences SET last_sequence = last_sequence + 1 "
                "WHERE chat_id = %s RETURNING last_sequence",
                (chat_id,),
            )
            row = cur.fetchone()
            if row is None:
                # First message in a chat created outside create_chat.
                cur.execute(
                    "INSERT INTO chat_sequences (chat_id, last_sequence) VALUES (%s, 1) "
                    "RETURNING last_sequence",
                    (chat_id,),
                )
                row = cur.fetchone()
            seq = row["last_sequence"]

            # 2. Insert the message itself.
            cur.execute(
                "INSERT INTO messages (chat_id, sender_id, content, encrypted_content, "
                "sequence_number) VALUES (%s, %s, %s, %s, %s) "
                "RETURNING id, server_timestamp",
                (chat_id, sender_id, content, encrypted, seq),
            )
            msg = cur.fetchone()
            msg_id = msg["id"]
            ts = msg["server_timestamp"].isoformat()

            # 3. Fan out: one inbox row per participant except the sender.
            cur.execute(
                "INSERT INTO inbox (user_id, message_id) "
                "SELECT user_id, %s FROM chat_participants "
                "WHERE chat_id = %s AND user_id != %s",
                (msg_id, chat_id, sender_id),
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
    """Client acknowledges receiving a message — mark the inbox row delivered.

    The `status = 'pending'` guard is what keeps the receipt state machine
    MONOTONE. Clients retry ACKs, and an ACK can arrive AFTER the read event
    (the UI shows the message the instant it lands, so 'read' can legitimately
    beat the delivery ACK on the wire). Without the guard, a late duplicate
    ACK would rewrite 'read' back to 'delivered' and the sender's checkmarks
    would go 🔵✓✓ -> ✓✓. Status only ever moves forwards.
    """
    message_id = payload["message_id"]
    row = db_execute(
        "UPDATE inbox SET status = 'delivered', delivered_at = NOW() "
        "WHERE user_id = %s AND message_id = %s AND status = 'pending' "
        "RETURNING id",
        (user_id, message_id),
    )
    # Only tell the sender ✓✓ on the transition, not on retries.
    if row:
        msg = db_fetch_one(
            "SELECT sender_id, chat_id FROM messages WHERE id = %s", (message_id,)
        )
        if msg:
            redis_client.publish(f"user:{msg['sender_id']}", json.dumps({
                "type": "delivery_receipt",
                "message_id": message_id,
                "recipient_id": user_id,
                "chat_id": msg["chat_id"],
            }))
    await send_json(ws, {"type": "ack_ok", "message_id": message_id})


async def handle_read(ws, user_id: int, payload: dict):
    """Client marks a message as read — update inbox and notify sender.

    Two details that keep the state machine honest:
      * `status != 'read'` makes a repeated read a no-op, so read_at records
        the FIRST read rather than the most recent one.
      * `COALESCE(delivered_at, NOW())` backfills delivery. A read implies a
        delivery, so 'read' must never be reached with delivered_at NULL --
        otherwise the sender's UI has a message that was read but never
        delivered.
    """
    message_id = payload["message_id"]
    row = db_execute(
        "UPDATE inbox SET status = 'read', read_at = NOW(), "
        "delivered_at = COALESCE(delivered_at, NOW()) "
        "WHERE user_id = %s AND message_id = %s AND status != 'read' "
        "RETURNING id",
        (user_id, message_id),
    )
    # Notify the original sender via pub/sub (only on the transition)
    if row:
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
        # Order by (chat, sequence) -- NOT by timestamp. The per-chat sequence
        # number is the ONLY authoritative order; a timestamp can tie, and it
        # comes from the DB clock rather than from the chat's own counter.
        # This also matches idx_messages_chat(chat_id, sequence_number).
        "ORDER BY m.chat_id, m.sequence_number",
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
async def redis_subscriber(user_id: int, ws, ready: asyncio.Event):
    """Subscribe to the user's Redis channel and forward messages.

    `ready` is not set until Redis has CONFIRMED the subscription. This is not
    ceremony: `pubsub.subscribe()` only writes bytes to a socket. Until Redis
    has actually processed that SUBSCRIBE, a PUBLISH arriving on a *different*
    connection is dropped on the floor -- pub/sub keeps no backlog for a
    channel nobody is listening to yet. Reading the subscribe confirmation
    proves the round-trip completed, so a client that has been told
    "connected" genuinely cannot miss a push that happens after it.
    """
    pubsub = redis_client.pubsub()
    channel = f"user:{user_id}"
    pubsub.subscribe(channel)
    try:
        # Drain the subscribe confirmation -- reading it is the proof.
        for _ in range(200):                       # ~2s budget, never blocking
            msg = pubsub.get_message(timeout=0)
            if msg and msg["type"] == "subscribe":
                break
            await asyncio.sleep(0.01)
        ready.set()
        await asyncio.sleep(0)   # let the handler resume and greet the client

        while True:
            # timeout=0 is a NON-BLOCKING poll, and that is the whole point.
            # A non-zero timeout here blocks the entire asyncio event loop --
            # not just this user, but every other connection and all request
            # handling stalls behind it. With N connected users the cost
            # compounds: each forwarded message waits behind up to N such
            # blocking reads. At 0.5s x 5 connections that measured ~3.5s of
            # added latency, against the ~50ms this design claims.
            forwarded = False
            while True:
                msg = pubsub.get_message(ignore_subscribe_messages=True, timeout=0)
                if not msg:
                    break
                if msg["type"] == "message":
                    await ws.send(msg["data"])
                    forwarded = True
            # Yield immediately if we just drained a backlog, otherwise idle
            # briefly so an idle connection is not a busy-wait.
            await asyncio.sleep(0 if forwarded else 0.02)
    except (websockets.exceptions.ConnectionClosed, asyncio.CancelledError):
        pass
    finally:
        ready.set()          # never leave the handler waiting on a dead task
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

        # Start the Redis subscription and wait for Redis to confirm it BEFORE
        # replying "connected". Otherwise a client can legitimately send a
        # message the instant it is greeted and have the reply published into
        # a channel it is not subscribed to yet -- silently lost.
        sub_ready = asyncio.Event()
        sub_task = asyncio.create_task(redis_subscriber(user_id, ws, sub_ready))
        try:
            await asyncio.wait_for(sub_ready.wait(), timeout=5)
        except asyncio.TimeoutError:
            print(f"[!] User {user_id}: Redis subscription not confirmed in 5s")

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
