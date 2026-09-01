"""
Google Docs-style Document Collaboration Server
=================================================
A minimal WebSocket server that demonstrates the core concepts of
a collaborative document editor: operational transformation (OT),
real-time sync, cursor presence, and document versioning.

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
    "dbname": os.getenv("DB_NAME", "googledocs_demo"),
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
# Maps document_id -> { "text": str, "version": int, "ops": [...] }
documents: dict[int, dict] = {}

# Maps document_id -> { user_id: { "ws": websocket, "cursor": int, "name": str, "color": str } }
doc_sessions: dict[int, dict] = {}

# Redis client
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------
def get_db():
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
# Operational Transformation (OT) — the heart of collaborative editing
# ---------------------------------------------------------------------------
def _make_delete(position, length, site):
    return {"type": "delete", "position": position, "content": "",
            "length": length, "site": site}


def transform_operation(op_a, op_b):
    """
    Transform operation B against operation A.

    Both ops were created against the same document state; A has already been
    applied. We adjust B so it still expresses the same intent afterwards.

    Each op is a dict: { "type": "insert"/"delete", "position": int,
                         "content": str, "length": int, "site": int }

    Returns a LIST of ops, to be applied in the order given:
      * 1 op  -- the normal case (a shifted position)
      * 2 ops -- A inserted inside the range B deletes, so B splits around it
      * 0 ops -- A already deleted everything B wanted to delete

    Notebook 1 derives these rules and checks them exhaustively (TP1).
    """
    if op_b["type"] == "insert":
        return [_transform_insert(op_a, op_b)]
    return _transform_delete(op_a, op_b)


def _transform_insert(op_a, op_b):
    """B is an INSERT. Inserts always survive -- only the position moves."""
    b = dict(op_b)

    if op_a["type"] == "insert":
        insert_len = len(op_a.get("content", ""))
        if b["position"] > op_a["position"]:
            b["position"] += insert_len
        elif b["position"] == op_a["position"]:
            # Both users typed at the same spot. The tie-break has to be
            # symmetric or the two clients end up with the words swapped, so
            # order by site (user) id -- a value both sides already agree on.
            if op_a.get("site", 0) <= b.get("site", 0):
                b["position"] += insert_len
    else:
        a_start = op_a["position"]
        a_end = a_start + op_a.get("length", 1)
        if b["position"] >= a_end:
            b["position"] -= (a_end - a_start)
        elif b["position"] > a_start:
            b["position"] = a_start        # typed inside the deleted run

    return b


def _transform_delete(op_a, op_b):
    """B is a DELETE of the half-open range [start, end). Returns 0, 1 or 2 ops."""
    site = op_b.get("site", 0)
    b_start = op_b["position"]
    b_end = b_start + op_b.get("length", 1)

    if op_a["type"] == "insert":
        p = op_a["position"]
        ins_len = len(op_a.get("content", ""))
        if p <= b_start:
            return [_make_delete(b_start + ins_len, b_end - b_start, site)]
        if p >= b_end:
            return [dict(op_b)]
        # A typed inside the range B deletes. Inserts always survive, so B
        # splits around the new text. Right half first: both positions are in
        # the same frame, and deleting the right range leaves the left valid.
        return [
            _make_delete(p + ins_len, b_end - p, site),
            _make_delete(b_start, p - b_start, site),
        ]

    # A is also a DELETE: B must only remove whatever A left behind, otherwise
    # two users backspacing the same word delete twice as much as either asked.
    a_start = op_a["position"]
    a_end = a_start + op_a.get("length", 1)
    overlap = max(0, min(a_end, b_end) - max(a_start, b_start))
    remaining = (b_end - b_start) - overlap
    if remaining <= 0:
        return []
    new_start = b_start - max(0, min(a_end, b_start) - a_start)
    return [_make_delete(new_start, remaining, site)]


def transform_operations(new_op, applied_ops):
    """
    Transform a new operation against the ops applied since the client's
    revision, in application order. Returns a LIST of ops.
    """
    pending = [dict(new_op)]
    for applied in applied_ops:
        pending = [t for p in pending for t in transform_operation(applied, p)]
        # A split delete leaves two ops in the same coordinate frame; applying
        # the rightmost first keeps the other one's position valid.
        pending.sort(key=lambda o: -o["position"])
    return pending


def transform_cursor(position, op):
    """Move a cursor so it keeps pointing at the same character after `op`.

    Without this, every remote edit above your caret silently drags it to the
    wrong place -- the presence dots in the notebook would lie.
    """
    if op["type"] == "insert":
        if position >= op["position"]:
            return position + len(op.get("content", ""))
        return position
    start = op["position"]
    end = start + op.get("length", 1)
    if position >= end:
        return position - (end - start)
    if position > start:
        return start
    return position


def apply_operation(text, op):
    """Apply a single operation to a text string and return the new text."""
    pos = op["position"]
    if op["type"] == "insert":
        return text[:pos] + op.get("content", "") + text[pos:]
    elif op["type"] == "delete":
        length = op.get("length", 1)
        return text[:pos] + text[pos + length:]
    return text


# ---------------------------------------------------------------------------
# Document management
# ---------------------------------------------------------------------------
def load_document(doc_id):
    """Load a document from the database into memory."""
    if doc_id in documents:
        return documents[doc_id]

    # Get the latest snapshot
    snap = db_fetch_one(
        "SELECT version, content FROM snapshots "
        "WHERE document_id = %s ORDER BY version DESC LIMIT 1",
        (doc_id,),
    )

    if snap:
        text = snap["content"]
        version = snap["version"]
    else:
        text = ""
        version = 0

    # Apply any operations after the snapshot
    ops = db_fetch_all(
        "SELECT op_type, position, content, length FROM operations "
        "WHERE document_id = %s AND version >= %s ORDER BY id",
        (doc_id, version),
    )
    for op in ops:
        op_dict = {
            "type": op["op_type"],
            "position": op["position"],
            "content": op["content"] or "",
            "length": op["length"] or 0,
        }
        text = apply_operation(text, op_dict)

    doc_state = {
        "text": text,
        "version": version,          # latest SNAPSHOT version
        "pending_ops": [],           # ops applied since the last snapshot
        # Every op applied since the doc was loaded, never cleared by a
        # snapshot. Its length is the document's "revision": the number a
        # client quotes so we know which ops it has not seen yet. Using the
        # snapshot version for this instead (it only moves every 50 ops)
        # means concurrent edits are never transformed at all.
        "ops_log": [],
    }
    documents[doc_id] = doc_state
    return doc_state


def create_snapshot(doc_id, user_id):
    """Create a new snapshot (compaction) of the document."""
    doc = documents.get(doc_id)
    if not doc:
        return None

    new_version = doc["version"] + 1
    op_count = len(doc["pending_ops"])

    db_execute(
        "INSERT INTO snapshots (document_id, version, content, op_count, created_by) "
        "VALUES (%s, %s, %s, %s, %s)",
        (doc_id, new_version, doc["text"], op_count, user_id),
    )
    db_execute(
        "UPDATE documents SET current_version = %s, updated_at = NOW() WHERE id = %s",
        (new_version, doc_id),
    )

    doc["version"] = new_version
    doc["pending_ops"] = []

    return new_version


# ---------------------------------------------------------------------------
# WebSocket helpers
# ---------------------------------------------------------------------------
async def send_json(ws, data):
    await ws.send(json.dumps(data, default=str))


async def broadcast_to_doc(doc_id, message, exclude_user=None):
    """Send a message to all users connected to a document.

    The session dict is snapshotted first: every send is an await point, and a
    client disconnecting during one mutates doc_sessions underneath the loop
    ("dictionary changed size during iteration"), which kills the whole
    connection handler mid-broadcast.
    """
    session = list(doc_sessions.get(doc_id, {}).items())
    for uid, info in session:
        if uid != exclude_user:
            try:
                await send_json(info["ws"], message)
            except websockets.exceptions.ConnectionClosed:
                pass


# ---------------------------------------------------------------------------
# Message handlers
# ---------------------------------------------------------------------------
async def handle_join_doc(ws, user_id, payload):
    """User joins a document for collaborative editing."""
    doc_id = payload["document_id"]

    # Check access
    collab = db_fetch_one(
        "SELECT role FROM collaborators WHERE document_id = %s AND user_id = %s",
        (doc_id, user_id),
    )
    if not collab:
        await send_json(ws, {"type": "error", "message": "No access to this document"})
        return

    # Load document into memory
    doc = load_document(doc_id)

    # Get user info for presence
    user = db_fetch_one("SELECT display_name, color FROM users WHERE id = %s", (user_id,))

    # Register this user's session
    doc_sessions.setdefault(doc_id, {})[user_id] = {
        "ws": ws,
        "cursor": 0,
        "name": user["display_name"],
        "color": user["color"],
        "role": collab["role"],
    }

    # Store in Redis for cross-server awareness (educational: single server here)
    redis_client.hset(f"doc:{doc_id}:presence", user_id, json.dumps({
        "name": user["display_name"],
        "color": user["color"],
        "cursor": 0,
    }))

    # Send current document state to the joining user
    await send_json(ws, {
        "type": "doc_state",
        "document_id": doc_id,
        "text": doc["text"],
        "version": doc["version"],
        "revision": len(doc["ops_log"]),
        "role": collab["role"],
    })

    # Send current presence (who else is editing)
    other_users = []
    for uid, info in doc_sessions.get(doc_id, {}).items():
        if uid != user_id:
            other_users.append({
                "user_id": uid,
                "name": info["name"],
                "color": info["color"],
                "cursor": info["cursor"],
            })
    await send_json(ws, {"type": "presence_list", "users": other_users})

    # Notify others that this user joined
    await broadcast_to_doc(doc_id, {
        "type": "user_joined",
        "user_id": user_id,
        "name": user["display_name"],
        "color": user["color"],
    }, exclude_user=user_id)

    print(f"  📄 User {user_id} joined doc {doc_id} ({len(doc_sessions[doc_id])} editors)")


async def handle_edit(ws, user_id, payload):
    """Handle an edit operation from a client."""
    doc_id = payload["document_id"]
    op = {
        "type": payload["op_type"],       # "insert" or "delete"
        "position": payload["position"],
        "content": payload.get("content", ""),
        "length": payload.get("length", 0),
        "site": user_id,                  # tie-break for same-position inserts
    }

    doc = documents.get(doc_id)
    if not doc:
        await send_json(ws, {"type": "error", "message": "Document not loaded"})
        return

    # Enforce role — viewers can see the doc but cannot edit
    session = doc_sessions.get(doc_id, {}).get(user_id)
    if session and session.get("role") == "viewer":
        await send_json(ws, {
            "type": "error",
            "message": "Permission denied: your role is 'viewer' (read-only).",
        })
        return

    # Transform against everything applied since the client's revision.
    # A client that does not send one is treated as up to date (no transform).
    revision = len(doc["ops_log"])
    client_revision = payload.get("revision", revision)
    client_revision = max(0, min(int(client_revision), revision))
    concurrent = doc["ops_log"][client_revision:]
    applied = transform_operations(op, concurrent) if concurrent else [dict(op)]

    for out in applied:
        doc["text"] = apply_operation(doc["text"], out)
        doc["ops_log"].append(out)
        doc["pending_ops"].append(out)

        # Persist the operation to the database
        db_execute(
            "INSERT INTO operations (document_id, user_id, version, op_type, position, content, length) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (doc_id, user_id, doc["version"], out["type"], out["position"],
             out.get("content", ""), out.get("length", 0)),
        )

    # Everyone else's caret has to move with the text they are looking at.
    for out in applied:
        move_cursors(doc_id, out, exclude_user=user_id)

    # ACK the sender, telling it which revision the document is now at
    await send_json(ws, {
        "type": "ack",
        "document_id": doc_id,
        "version": doc["version"],
        "revision": len(doc["ops_log"]),
        "transformed": [
            {"op_type": o["type"], "position": o["position"],
             "content": o.get("content", ""), "length": o.get("length", 0)}
            for o in applied
        ],
        "op_count": len(doc["pending_ops"]),
    })

    # Broadcast the (transformed) operations to other editors
    for out in applied:
        await broadcast_to_doc(doc_id, {
            "type": "remote_op",
            "document_id": doc_id,
            "user_id": user_id,
            "op_type": out["type"],
            "position": out["position"],
            "content": out.get("content", ""),
            "length": out.get("length", 0),
            "revision": len(doc["ops_log"]),
        }, exclude_user=user_id)

    # Auto-snapshot every 50 operations
    if len(doc["pending_ops"]) >= 50:
        new_ver = create_snapshot(doc_id, user_id)
        if new_ver:
            await broadcast_to_doc(doc_id, {
                "type": "snapshot_created",
                "document_id": doc_id,
                "version": new_ver,
            })


def move_cursors(doc_id, op, exclude_user=None):
    """Shift every other editor's cursor to follow the text it was pointing at."""
    for uid, info in doc_sessions.get(doc_id, {}).items():
        if uid == exclude_user:
            continue
        moved = transform_cursor(info["cursor"], op)
        if moved == info["cursor"]:
            continue
        info["cursor"] = moved
        redis_client.hset(f"doc:{doc_id}:presence", uid, json.dumps({
            "name": info["name"],
            "color": info["color"],
            "cursor": moved,
        }))


async def handle_cursor_update(ws, user_id, payload):
    """Handle a cursor position update for presence awareness."""
    doc_id = payload["document_id"]
    position = payload["position"]

    session = doc_sessions.get(doc_id, {})
    if user_id in session:
        session[user_id]["cursor"] = position

    # Update Redis
    redis_client.hset(f"doc:{doc_id}:presence", user_id, json.dumps({
        "name": session.get(user_id, {}).get("name", ""),
        "color": session.get(user_id, {}).get("color", ""),
        "cursor": position,
    }))

    # Broadcast to other editors
    await broadcast_to_doc(doc_id, {
        "type": "cursor_update",
        "user_id": user_id,
        "position": position,
    }, exclude_user=user_id)


async def handle_create_doc(ws, user_id, payload):
    """Create a new document."""
    title = payload.get("title", "Untitled Document")

    doc = db_execute(
        "INSERT INTO documents (title, owner_id) VALUES (%s, %s) RETURNING id",
        (title, user_id),
    )
    doc_id = doc["id"]

    # Add creator as owner + collaborator
    db_execute(
        "INSERT INTO collaborators (document_id, user_id, role) VALUES (%s, %s, 'owner')",
        (doc_id, user_id),
    )

    # Create initial empty snapshot
    db_execute(
        "INSERT INTO snapshots (document_id, version, content, op_count, created_by) "
        "VALUES (%s, 0, '', 0, %s)",
        (doc_id, user_id),
    )

    await send_json(ws, {"type": "doc_created", "document_id": doc_id, "title": title})


async def handle_save_snapshot(ws, user_id, payload):
    """Manually trigger a snapshot/compaction."""
    doc_id = payload["document_id"]
    doc = documents.get(doc_id)
    if not doc:
        await send_json(ws, {"type": "error", "message": "Document not loaded"})
        return

    new_ver = create_snapshot(doc_id, user_id)
    await send_json(ws, {
        "type": "snapshot_saved",
        "document_id": doc_id,
        "version": new_ver,
    })


async def handle_get_history(ws, user_id, payload):
    """Return the version history (snapshots) for a document."""
    doc_id = payload["document_id"]

    snapshots = db_fetch_all(
        "SELECT s.version, s.content, s.op_count, s.created_at, u.display_name AS created_by "
        "FROM snapshots s JOIN users u ON s.created_by = u.id "
        "WHERE s.document_id = %s ORDER BY s.version DESC",
        (doc_id,),
    )

    await send_json(ws, {
        "type": "version_history",
        "document_id": doc_id,
        "versions": [
            {
                "version": s["version"],
                "content": s["content"],
                "op_count": s["op_count"],
                "created_at": s["created_at"].isoformat() if s["created_at"] else None,
                "created_by": s["created_by"],
            }
            for s in snapshots
        ],
    })


async def handle_restore_version(ws, user_id, payload):
    """Restore a document to a previous snapshot version."""
    doc_id = payload["document_id"]
    target_version = payload["version"]

    snap = db_fetch_one(
        "SELECT content FROM snapshots WHERE document_id = %s AND version = %s",
        (doc_id, target_version),
    )
    if not snap:
        await send_json(ws, {"type": "error", "message": "Version not found"})
        return

    # Create a new snapshot with the restored content
    doc = load_document(doc_id)
    doc["text"] = snap["content"]
    doc["pending_ops"] = []
    doc["ops_log"] = []      # every client's revision is meaningless now
    new_ver = create_snapshot(doc_id, user_id)

    # Broadcast the restored document to all editors
    await broadcast_to_doc(doc_id, {
        "type": "doc_state",
        "document_id": doc_id,
        "text": snap["content"],
        "version": new_ver,
        "revision": 0,
        "role": "editor",
    })

    await send_json(ws, {
        "type": "version_restored",
        "document_id": doc_id,
        "restored_version": target_version,
        "new_version": new_ver,
    })


HANDLERS = {
    "join_doc": handle_join_doc,
    "edit": handle_edit,
    "cursor_update": handle_cursor_update,
    "create_doc": handle_create_doc,
    "save_snapshot": handle_save_snapshot,
    "get_history": handle_get_history,
    "restore_version": handle_restore_version,
}


# ---------------------------------------------------------------------------
# Connection lifecycle
# ---------------------------------------------------------------------------
async def handle_disconnect(user_id, doc_ids):
    """Clean up when a user disconnects."""
    for doc_id in doc_ids:
        session = doc_sessions.get(doc_id, {})
        if user_id in session:
            del session[user_id]
            redis_client.hdel(f"doc:{doc_id}:presence", user_id)

            await broadcast_to_doc(doc_id, {
                "type": "user_left",
                "user_id": user_id,
            })

            # If no one is editing, snapshot and unload
            if not session:
                if doc_id in documents and documents[doc_id]["pending_ops"]:
                    create_snapshot(doc_id, user_id)
                documents.pop(doc_id, None)
                doc_sessions.pop(doc_id, None)
                redis_client.delete(f"doc:{doc_id}:presence")
                print(f"  📄 Doc {doc_id} unloaded (no editors)")


async def handler(ws):
    """Handle a single WebSocket connection lifecycle."""
    user_id = None
    joined_docs = set()

    try:
        # First message must be a connect message
        raw = await ws.recv()
        data = json.loads(raw)
        if data.get("type") != "connect":
            await send_json(ws, {"type": "error", "message": "First message must be type 'connect'"})
            return

        user_id = int(data["user_id"])
        await send_json(ws, {"type": "connected", "user_id": user_id})
        print(f"[+] User {user_id} connected")

        # Main message loop
        async for raw in ws:
            try:
                data = json.loads(raw)
                msg_type = data.get("type")

                # Track which docs this user joined
                if msg_type == "join_doc":
                    joined_docs.add(data["document_id"])

                handler_fn = HANDLERS.get(msg_type)
                if handler_fn:
                    await handler_fn(ws, user_id, data)
                elif msg_type == "heartbeat":
                    await send_json(ws, {"type": "heartbeat_ack"})
                else:
                    await send_json(ws, {"type": "error", "message": f"Unknown type: {msg_type}"})
            except Exception as e:
                await send_json(ws, {"type": "error", "message": str(e)})

    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        if user_id is not None:
            await handle_disconnect(user_id, joined_docs)
            print(f"[-] User {user_id} disconnected")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
async def main():
    print(f"🚀 Google Docs Collaboration Server starting on ws://{WS_HOST}:{WS_PORT}")
    async with websockets.serve(handler, WS_HOST, WS_PORT):
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    asyncio.run(main())
