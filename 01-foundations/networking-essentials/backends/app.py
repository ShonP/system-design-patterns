"""
Simple Flask backend server for networking-essentials lab.
Each instance identifies itself so you can see load balancing in action.
"""

import os
import time
import socket
from flask import Flask, request, jsonify

app = Flask(__name__)

# Each backend container sets its own SERVER_NAME via environment variable
SERVER_NAME = os.environ.get("SERVER_NAME", "unknown")


@app.route("/")
def index():
    """Return info about which backend handled this request."""
    return jsonify({
        "server": SERVER_NAME,
        "hostname": socket.gethostname(),
        "message": f"Hello from {SERVER_NAME}!",
        "client_ip": request.remote_addr,
        "timestamp": time.time(),
    })


@app.route("/health")
def health():
    """Health check endpoint used by nginx to know if this server is alive."""
    return jsonify({"status": "healthy", "server": SERVER_NAME})


@app.route("/slow")
def slow():
    """Simulate a slow response — useful for testing least-connections LB."""
    delay = float(request.args.get("delay", 2))
    time.sleep(delay)
    return jsonify({"server": SERVER_NAME, "delay_seconds": delay})


@app.route("/echo", methods=["GET", "POST", "PUT", "DELETE"])
def echo():
    """Echo back whatever the client sends — useful for HTTP method demos."""
    return jsonify({
        "server": SERVER_NAME,
        "method": request.method,
        "path": request.path,
        "headers": dict(request.headers),
        "args": dict(request.args),
        "data": request.get_json(silent=True),
    })


@app.route("/headers")
def headers():
    """Show all request headers — useful for seeing what nginx adds."""
    return jsonify({
        "server": SERVER_NAME,
        "headers": dict(request.headers),
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
