import asyncio
import websockets
import json
from datetime import datetime
from collections import defaultdict

rooms: dict[str, set] = defaultdict(set)
client_info: dict = {}

# Demo-only "token database". A real server would verify a JWT signature or
# look the session up in Redis. The important part is WHERE this happens:
# server-side, during the handshake, with the identity taken from the token
# rather than from whatever username the client claims.
VALID_TOKENS: dict[str, str] = {
    "jwt-alice-xyz": "alice",
    "jwt-bob-pqr": "bob",
}

async def broadcast_to_room(room: str, message: dict, exclude=None):
    if room not in rooms:
        return
    message_json = json.dumps(message)
    # Iterate a snapshot: `await client.send(...)` yields to the event loop,
    # and another coroutine joining or leaving would otherwise mutate the set
    # mid-iteration ("Set changed size during iteration").
    for client in list(rooms[room]):
        if client != exclude:
            try:
                await client.send(message_json)
            except websockets.exceptions.ConnectionClosed:
                pass

async def handle_client(websocket):
    try:
        join_message = await websocket.recv()
        data = json.loads(join_message)
        
        if data.get("type") != "join":
            await websocket.close(1008, "First message must be join")
            return

        # --- Authentication happens here, once, on the first frame ----------
        # 1008 = "policy violation", the conventional close code for auth
        # failures. Closing is what makes the check real: without it a client
        # can keep the raw socket open and keep talking.
        token = data.get("token")
        if token is not None:
            if token not in VALID_TOKENS:
                print(f"🚫 rejected join: invalid token {token!r}")
                await websocket.close(1008, "invalid token")
                return
            # Identity comes from the token, NOT from data["username"].
            username = VALID_TOKENS[token]
        else:
            # The lab's other notebooks join without a token so they keep
            # working. A production server would reject this outright.
            username = data.get("username", "anonymous")

        room = data.get("room", "general")
        
        rooms[room].add(websocket)
        client_info[websocket] = {"username": username, "room": room}
        
        print(f"📱 {username} joined room '{room}' (total in room: {len(rooms[room])})")
        
        await websocket.send(json.dumps({"type": "system", "message": f"Welcome to {room}!", "users_in_room": len(rooms[room]), "authenticated_as": username}))
        await broadcast_to_room(room, {"type": "system", "message": f"{username} joined the room", "users_in_room": len(rooms[room])}, exclude=websocket)
        
        async for message in websocket:
            try:
                data = json.loads(message)
            except json.JSONDecodeError:
                # A malformed frame must not take the whole connection down.
                await websocket.send(json.dumps({"type": "error", "message": "invalid JSON"}))
                continue
            
            if data.get("type") == "message":
                await broadcast_to_room(room, {"type": "message", "username": username, "text": data.get("text", ""), "timestamp": datetime.now().isoformat()})
                print(f"💬 [{room}] {username}: {data.get('text', '')}")
            elif data.get("type") == "typing":
                await broadcast_to_room(room, {"type": "typing", "username": username}, exclude=websocket)
                
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        if websocket in client_info:
            info = client_info.pop(websocket)
            room = info["room"]
            username = info["username"]
            rooms[room].discard(websocket)
            if not rooms[room]:
                # Otherwise `rooms` grows one empty set per room, forever.
                rooms.pop(room, None)
            print(f"📴 {username} left room '{room}' (remaining: {len(rooms.get(room, ()))})")
            await broadcast_to_room(room, {"type": "system", "message": f"{username} left the room", "users_in_room": len(rooms.get(room, ()))})

async def main():
    print("🚀 Starting WebSocket Server on port 5004")
    async with websockets.serve(handle_client, "localhost", 5004):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
