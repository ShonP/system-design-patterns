"""
User Service - A simple Flask API for managing users.

This service is intentionally simple — it stores everything in memory
so you can focus on learning API Gateway concepts, not database setup.

Each instance gets a unique INSTANCE_ID (set in docker-compose) so you
can see which instance handled your request. This is how we demonstrate
load balancing.
"""

from flask import Flask, jsonify, request
import os
import time

app = Flask(__name__)

# Each container gets a unique ID — watch this change when load balancing works!
INSTANCE_ID = os.environ.get("INSTANCE_ID", "1")

# Simple in-memory "database" — resets when the container restarts
users_db = {
    "1": {"id": "1", "name": "Alice Johnson", "email": "alice@example.com", "role": "admin"},
    "2": {"id": "2", "name": "Bob Smith", "email": "bob@example.com", "role": "user"},
    "3": {"id": "3", "name": "Charlie Brown", "email": "charlie@example.com", "role": "user"},
    "4": {"id": "4", "name": "Diana Prince", "email": "diana@example.com", "role": "moderator"},
}
next_id = 5


@app.route("/health")
def health():
    """Health check — the API gateway uses this to know if the service is alive."""
    return jsonify({
        "status": "healthy",
        "service": "user-service",
        "instance": INSTANCE_ID
    })


@app.route("/users", methods=["GET"])
def list_users():
    """List all users. The response includes served_by so you can see load balancing."""
    api_version = request.headers.get("X-API-Version", "1")

    response = {
        "users": list(users_db.values()),
        "count": len(users_db),
        "served_by": f"user-service-{INSTANCE_ID}"
    }

    # API v2 adds extra metadata (used in notebook 3 to demo versioning)
    if api_version == "2":
        response["_metadata"] = {
            "api_version": "2",
            "timestamp": time.time(),
            "instance": INSTANCE_ID,
            "total_records": len(users_db)
        }

    return jsonify(response)


@app.route("/users/<user_id>", methods=["GET"])
def get_user(user_id):
    """Get a single user by ID."""
    user = users_db.get(user_id)
    if not user:
        return jsonify({"error": "User not found", "served_by": f"user-service-{INSTANCE_ID}"}), 404

    api_version = request.headers.get("X-API-Version", "1")
    response = {**user, "served_by": f"user-service-{INSTANCE_ID}"}

    if api_version == "2":
        response["_metadata"] = {
            "api_version": "2",
            "timestamp": time.time(),
            "instance": INSTANCE_ID
        }

    return jsonify(response)


@app.route("/users", methods=["POST"])
def create_user():
    """Create a new user."""
    global next_id
    data = request.get_json()

    if not data or "name" not in data or "email" not in data:
        return jsonify({"error": "Missing required fields: 'name' and 'email'"}), 400

    user_id = str(next_id)
    next_id += 1

    users_db[user_id] = {
        "id": user_id,
        "name": data["name"],
        "email": data["email"],
        "role": data.get("role", "user")
    }

    return jsonify({**users_db[user_id], "served_by": f"user-service-{INSTANCE_ID}"}), 201


@app.route("/debug/headers", methods=["GET"])
def debug_headers():
    """Return all received request headers.
    
    This is a special endpoint for the notebooks — it lets you see
    exactly which headers the API gateway injected into the request.
    """
    headers = {key: value for key, value in request.headers}
    return jsonify({
        "received_headers": headers,
        "served_by": f"user-service-{INSTANCE_ID}"
    })


if __name__ == "__main__":
    print(f"🚀 User Service (Instance {INSTANCE_ID}) starting on port 5000...")
    app.run(host="0.0.0.0", port=5000, debug=False)
