"""
Rate-Limited Flask API Server
=============================
A simple Flask API with Redis-backed token bucket rate limiting.
Used by Notebook 4 to demonstrate API gateway-level rate limiting.

Run with: python server.py
Or via docker-compose: docker-compose up -d
"""

import os
import time
import json
from flask import Flask, request, jsonify, g
import redis

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Redis connection
# ---------------------------------------------------------------------------
REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
FLASK_PORT = int(os.environ.get("FLASK_PORT", 5050))

redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

# ---------------------------------------------------------------------------
# Token Bucket Lua script (atomic read + calculate + update)
# ---------------------------------------------------------------------------
TOKEN_BUCKET_SCRIPT = """
local key = KEYS[1]
local max_tokens = tonumber(ARGV[1])
local refill_rate = tonumber(ARGV[2])
local now = tonumber(ARGV[3])

-- Get current bucket state
local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
local tokens = tonumber(bucket[1])
local last_refill = tonumber(bucket[2])

-- Initialize bucket if it doesn't exist
if tokens == nil then
    tokens = max_tokens
    last_refill = now
end

-- Calculate tokens to add based on elapsed time
local elapsed = now - last_refill
local new_tokens = elapsed * refill_rate
tokens = math.min(max_tokens, tokens + new_tokens)

-- Try to consume a token
local allowed = 0
if tokens >= 1 then
    tokens = tokens - 1
    allowed = 1
end

-- Update bucket state
redis.call('HMSET', key, 'tokens', tokens, 'last_refill', now)
redis.call('EXPIRE', key, 3600)

return {allowed, math.floor(tokens), math.floor(max_tokens / refill_rate)}
"""

# Register the Lua script with Redis at startup
token_bucket_sha = None

def get_script_sha():
    """Register Lua script with Redis (lazy initialization)."""
    global token_bucket_sha
    if token_bucket_sha is None:
        token_bucket_sha = redis_client.script_load(TOKEN_BUCKET_SCRIPT)
    return token_bucket_sha


# ---------------------------------------------------------------------------
# Rate limit configuration
# ---------------------------------------------------------------------------
RATE_LIMIT_RULES = {
    "default": {"max_tokens": 10, "refill_rate": 1},       # 10 burst, 1/sec refill
    "search":  {"max_tokens": 5,  "refill_rate": 0.5},     # 5 burst, 1 every 2 sec
    "premium": {"max_tokens": 50, "refill_rate": 10},       # 50 burst, 10/sec refill
}


def identify_client():
    """Extract client identifier from the HTTP request.
    Priority: API key > User ID from header > IP address.
    """
    api_key = request.headers.get("X-API-Key")
    if api_key:
        return f"apikey:{api_key}"

    user_id = request.headers.get("X-User-Id")
    if user_id:
        return f"user:{user_id}"

    return f"ip:{request.remote_addr}"


def check_rate_limit(client_id, rule_name="default"):
    """Check if the request is within rate limits using token bucket."""
    rule = RATE_LIMIT_RULES.get(rule_name, RATE_LIMIT_RULES["default"])
    key = f"ratelimit:{rule_name}:{client_id}"
    now = time.time()

    try:
        sha = get_script_sha()
        try:
            result = redis_client.evalsha(
                sha, 1, key,
                rule["max_tokens"],
                rule["refill_rate"],
                now,
            )
        except redis.exceptions.NoScriptError:
            # Redis was restarted or flushed its script cache — reload the script.
            # This is a real production concern: evalsha fails if the cached SHA
            # is gone, so we fall back to loading and evaluating by source.
            global token_bucket_sha
            token_bucket_sha = redis_client.script_load(TOKEN_BUCKET_SCRIPT)
            result = redis_client.evalsha(
                token_bucket_sha, 1, key,
                rule["max_tokens"],
                rule["refill_rate"],
                now,
            )
        allowed = bool(result[0])
        remaining = int(result[1])
        reset_seconds = int(result[2])
        reset_time = int(now) + reset_seconds

        return {
            "allowed": allowed,
            "limit": rule["max_tokens"],
            "remaining": remaining,
            "reset": reset_time,
            "retry_after": 0 if allowed else reset_seconds,
        }
    except redis.ConnectionError:
        # Fail closed — reject if Redis is unavailable
        return {
            "allowed": False,
            "limit": rule["max_tokens"],
            "remaining": 0,
            "reset": int(now) + 60,
            "retry_after": 60,
        }


# ---------------------------------------------------------------------------
# Rate limiting middleware
# ---------------------------------------------------------------------------
@app.before_request
def rate_limit_middleware():
    """Middleware that runs before every request to check rate limits."""
    # Skip rate limiting for the health endpoint
    if request.path == "/health":
        return None

    client_id = identify_client()
    # Map the URL path to a rate limit rule
    if "/search" in request.path:
        rule_name = "search"
    elif "/premium" in request.path:
        rule_name = "premium"
    else:
        rule_name = "default"
    result = check_rate_limit(client_id, rule_name)

    # Store for use in after_request
    g.rate_limit = result
    g.client_id = client_id

    if not result["allowed"]:
        response = jsonify({
            "error": "Rate limit exceeded",
            "message": f"Try again in {result['retry_after']} seconds.",
        })
        response.status_code = 429
        response.headers["X-RateLimit-Limit"] = str(result["limit"])
        response.headers["X-RateLimit-Remaining"] = str(result["remaining"])
        response.headers["X-RateLimit-Reset"] = str(result["reset"])
        response.headers["Retry-After"] = str(result["retry_after"])
        return response


@app.after_request
def add_rate_limit_headers(response):
    """Add rate limit headers to every successful response too."""
    rate_limit = getattr(g, "rate_limit", None)
    if rate_limit:
        response.headers["X-RateLimit-Limit"] = str(rate_limit["limit"])
        response.headers["X-RateLimit-Remaining"] = str(rate_limit["remaining"])
        response.headers["X-RateLimit-Reset"] = str(rate_limit["reset"])
    return response


# ---------------------------------------------------------------------------
# API endpoints
# ---------------------------------------------------------------------------
@app.route("/health")
def health():
    """Health check — not rate limited."""
    return jsonify({"status": "ok"})


@app.route("/api/data")
def get_data():
    """Example API endpoint — rate limited."""
    return jsonify({
        "message": "Here is your data!",
        "client": g.client_id,
        "timestamp": time.time(),
    })


@app.route("/api/search")
def search():
    """Search endpoint — stricter rate limit."""
    query = request.args.get("q", "")
    return jsonify({
        "message": f"Search results for: {query}",
        "client": g.client_id,
        "results": ["result1", "result2", "result3"],
    })


@app.route("/api/premium")
def premium():
    """Premium endpoint — demonstrates tier-based limits (50 burst, 10/sec)."""
    return jsonify({
        "message": "Premium data access",
        "client": g.client_id,
    })


if __name__ == "__main__":
    print(f"🚦 Rate-Limited API running on port {FLASK_PORT}")
    print(f"📡 Redis: {REDIS_HOST}:{REDIS_PORT}")
    print(f"📋 Rules: {json.dumps(RATE_LIMIT_RULES, indent=2)}")
    app.run(host="0.0.0.0", port=FLASK_PORT, debug=False)
