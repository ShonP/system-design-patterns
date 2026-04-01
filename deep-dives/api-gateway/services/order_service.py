"""
Order Service - A simple Flask API for managing orders.

This is the second backend service in our API Gateway lab.
Having two different services lets us demonstrate path-based routing:
  /api/users  → User Service
  /api/orders → Order Service
"""

from flask import Flask, jsonify, request
import os
import time

app = Flask(__name__)

INSTANCE_ID = os.environ.get("INSTANCE_ID", "1")

# Simple in-memory "database"
orders_db = {
    "101": {"id": "101", "user_id": "1", "product": "Laptop", "amount": 999.99, "status": "shipped"},
    "102": {"id": "102", "user_id": "2", "product": "Keyboard", "amount": 79.99, "status": "delivered"},
    "103": {"id": "103", "user_id": "1", "product": "Mouse", "amount": 29.99, "status": "processing"},
    "104": {"id": "104", "user_id": "3", "product": "Monitor", "amount": 349.99, "status": "shipped"},
}
next_id = 105


@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "order-service",
        "instance": INSTANCE_ID
    })


@app.route("/orders", methods=["GET"])
def list_orders():
    """List orders. Supports optional ?user_id= filter."""
    api_version = request.headers.get("X-API-Version", "1")

    # Optional filter by user_id query parameter
    user_id = request.args.get("user_id")
    if user_id:
        filtered = [o for o in orders_db.values() if o["user_id"] == user_id]
    else:
        filtered = list(orders_db.values())

    response = {
        "orders": filtered,
        "count": len(filtered),
        "served_by": f"order-service-{INSTANCE_ID}"
    }

    if api_version == "2":
        response["_metadata"] = {
            "api_version": "2",
            "timestamp": time.time(),
            "instance": INSTANCE_ID
        }

    return jsonify(response)


@app.route("/orders/<order_id>", methods=["GET"])
def get_order(order_id):
    """Get a single order by ID."""
    order = orders_db.get(order_id)
    if not order:
        return jsonify({"error": "Order not found", "served_by": f"order-service-{INSTANCE_ID}"}), 404

    api_version = request.headers.get("X-API-Version", "1")
    response = {**order, "served_by": f"order-service-{INSTANCE_ID}"}

    if api_version == "2":
        response["_metadata"] = {
            "api_version": "2",
            "timestamp": time.time()
        }

    return jsonify(response)


@app.route("/orders", methods=["POST"])
def create_order():
    """Create a new order."""
    global next_id
    data = request.get_json()

    if not data or "user_id" not in data or "product" not in data:
        return jsonify({"error": "Missing required fields: 'user_id' and 'product'"}), 400

    order_id = str(next_id)
    next_id += 1

    orders_db[order_id] = {
        "id": order_id,
        "user_id": data["user_id"],
        "product": data["product"],
        "amount": data.get("amount", 0),
        "status": "processing"
    }

    return jsonify({**orders_db[order_id], "served_by": f"order-service-{INSTANCE_ID}"}), 201


@app.route("/debug/headers", methods=["GET"])
def debug_headers():
    """Return all received request headers — useful for gateway inspection."""
    headers = {key: value for key, value in request.headers}
    return jsonify({
        "received_headers": headers,
        "served_by": f"order-service-{INSTANCE_ID}"
    })


if __name__ == "__main__":
    print(f"🚀 Order Service (Instance {INSTANCE_ID}) starting on port 5000...")
    app.run(host="0.0.0.0", port=5000, debug=False)
