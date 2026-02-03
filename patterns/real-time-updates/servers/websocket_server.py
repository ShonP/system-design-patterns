import asyncio
import websockets
import json
from datetime import datetime
from collections import defaultdict

rooms: dict[str, set] = defaultdict(set)
client_info: dict = {}

async def broadcast_to_room(room: str, message: dict, exclude=None):
    if room not in rooms:
        return
    message_json = json.dumps(message)
    for client in rooms[room]:
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
        
        username = data.get("username", "anonymous")
        room = data.get("room", "general")
        
        rooms[room].add(websocket)
        client_info[websocket] = {"username": username, "room": room}
        
        print(f"📱 {username} joined room '{room}' (total in room: {len(rooms[room])})")
        
        await websocket.send(json.dumps({"type": "system", "message": f"Welcome to {room}!", "users_in_room": len(rooms[room])}))
        await broadcast_to_room(room, {"type": "system", "message": f"{username} joined the room", "users_in_room": len(rooms[room])}, exclude=websocket)
        
        async for message in websocket:
            data = json.loads(message)
            
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
            print(f"📴 {username} left room '{room}' (remaining: {len(rooms[room])})")
            await broadcast_to_room(room, {"type": "system", "message": f"{username} left the room", "users_in_room": len(rooms[room])})

async def main():
    print("🚀 Starting WebSocket Server on port 5004")
    async with websockets.serve(handle_client, "localhost", 5004):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
