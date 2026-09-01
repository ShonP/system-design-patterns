"""
Rate-Limited Flask API Server
=============================
A Flask API with Redis-backed token bucket rate limiting.
Used by Notebook 4 to demonstrate API gateway-level rate limiting.

Run with: python server.py
Or via docker-compose: docker compose up -d
"""

import math
import os
import time

import redis
from flask import Flask, g, jsonify, request

app = Flask(__name__)

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
FLASK_PORT = int(os.environ.get("FLASK_PORT", 5050))

# What to do when Redis is unreachable.
#   "open"   -> allow the request. The API stays up, but is unprotected.
#   "closed" -> reject with 429. The API is protected, but is effectively down.
# Most teams pick "open" and page someone, because a rate limiter outage
# taking down the whole API is a worse failure than a few minutes of
# unlimited traffic. Pick "closed" only when the thing behind the limiter
# is more expensive than the outage (billing, LLM inference, SMS sends).
FAIL_MODE = os.environ.get("RATE_LIMIT_FAIL_MODE", "open")

redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True,
                          socket_timeout=2, socket_connect_timeout=2)

# ---------------------------------------------------------------------------
# Token Bucket Lua script (atomic read + calculate + update)
# ---------------------------------------------------------------------------
# Everything below runs inside Redis as one uninterruptible operation, so the
# read-check-write sequence can never interleave with another gateway's.
TOKEN_BUCKET_SCRIPT = """
local key = KEYS[1]
local max_tokens = tonumber(ARGV[1])
local refill_rate = tonumber(ARGV[2])   -- tokens per second

-- Server-authoritative clock. Taking `now` from the *caller* is a classic bug:
-- gateways whose clocks are a few seconds fast hand out free tokens, because
-- the script sees a huge `elapsed`. Reading TIME here means every gateway in
-- the fleet shares one timeline, whatever their local clocks say.
local t = redis.call('TIME')
local now = tonumber(t[1]) + tonumber(t[2]) / 1000000

local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
local tokens = tonumber(bucket[1])
local last_refill = tonumber(bucket[2])

if tokens == nil then          -- first request from this client
    tokens = max_tokens
    last_refill = now
end

-- Lazy refill: add the tokens that *would* have dripped in since last time.
local elapsed = math.max(0, now - last_refill)
tokens = math.min(max_tokens, tokens + elapsed * refill_rate)

local allowed = 0
if tokens >= 1 then
    tokens = tokens - 1
    allowed = 1
end

redis.call('HSET', key, 'tokens', tostring(tokens), 'last_refill', tostring(now))
redis.call('EXPIRE', key, 3600)   -- inactive buckets evaporate; no memory leak

-- Retry-After: how long until ONE whole token exists again. This is the only
-- number a rejected client actually needs. (Telling them to wait for a *full*
-- bucket, max_tokens/refill_rate, is a common and expensive mistake.)
local retry_after_ms = 0
if allowed == 0 and refill_rate > 0 then
    retry_after_ms = math.ceil(((1 - tokens) / refill_rate) * 1000)
end

-- X-RateLimit-Reset: when the bucket is completely refilled.
local reset_ms = 0
if refill_rate > 0 then
    reset_ms = math.ceil(((max_tokens - tokens) / refill_rate) * 1000)
end

-- Redis truncates Lua numbers to integers, so tokens travels as milli-tokens.
return {allowed, math.floor(tokens * 1000), retry_after_ms, reset_ms}
"""

token_bucket_sha = None


def get_script_sha():
    """Register the Lua script with Redis (lazy, cached)."""
    global token_bucket_sha
    if token_bucket_sha is None:
        token_bucket_sha = redis_client.script_load(TOKEN_BUCKET_SCRIPT)
    return token_bucket_sha


RATE_LIMIT_RULES = {
    "default": {"max_tokens": 10, "refill_rate": 1},       # 10 burst, 1/sec refill
    "search":  {"max_tokens": 5,  "refill_rate": 0.5},     # 5 burst, 1 every 2 sec
    "premium": {"max_tokens": 50, "refill_rate": 10},      # 50 burst, 10/sec refill
}


def identify_client():
    """Extract a client identifier. Priority: API key > user id > IP."""
    api_key = request.headers.get("X-API-Key")
    if api_key:
        return f"apikey:{api_key}"
    user_id = request.headers.get("X-User-Id")
    if user_id:
        return f"user:{user_id}"
    return f"ip:{request.remote_addr}"


def _run_script(key, rule):
    """evalsha, reloading the script if Redis dropped it from its cache."""
    try:
        return redis_client.evalsha(get_script_sha(), 1, key,
                                    rule["max_tokens"], rule["refill_rate"])
    except redis.exceptions.NoScriptError:
        # Redis restarted or SCRIPT FLUSH ran — the cached SHA is gone.
        global token_bucket_sha
        token_bucket_sha = redis_client.script_load(TOKEN_BUCKET_SCRIPT)
        return redis_client.evalsha(token_bucket_sha, 1, key,
                                    rule["max_tokens"], rule["refill_rate"])


def check_rate_limit(client_id, rule_name="default"):
    """Token-bucket check. Returns the decision plus everything the headers need."""
    rule = RATE_LIMIT_RULES.get(rule_name, RATE_LIMIT_RULES["default"])
    key = f"ratelimit:{rule_name}:{client_id}"
    now = time.time()

    try:
        allowed_i, milli_tokens, retry_after_ms, reset_ms = _run_script(key, rule)
    except redis.RedisError:
        # Redis is unreachable. See FAIL_MODE above for why this is a judgement call.
        allow = FAIL_MODE == "open"
        return {"allowed": allow, "limit": rule["max_tokens"], "remaining": 0,
                "reset": int(now) + 60, "retry_after": 0 if allow else 60,
                "degraded": True}

    # Retry-After is defined as whole seconds (RFC 9110), so we round up: a
    # client that waits the value we send is always past the refill, never short.
    retry_after = max(1, math.ceil(retry_after_ms / 1000)) if not allowed_i else 0

    return {
        "allowed": bool(allowed_i),
        "limit": rule["max_tokens"],
        "remaining": int(milli_tokens // 1000),
        "reset": int(now) + math.ceil(reset_ms / 1000),
        "retry_after": retry_after,
        "degraded": False,
    }


@app.before_request
def rate_limit_middleware():
    """Runs before every route handler. This is the gateway."""
    if request.path == "/health":
        return None

    client_id = identify_client()
    if "/search" in request.path:
        rule_name = "search"
    elif "/premium" in request.path:
        rule_name = "premium"
    else:
        rule_name = "default"

    result = check_rate_limit(client_id, rule_name)
    g.rate_limit = result
    g.client_id = client_id

    if not result["allowed"]:
        response = jsonify({
            "error": "Rate limit exceeded",
            "message": f"Try again in {result['retry_after']} seconds.",
        })
        response.status_code = 429
        response.headers["Retry-After"] = str(result["retry_after"])
        return response


@app.after_request
def add_rate_limit_headers(response):
    """Rate limit headers go on *every* response, not just the 429."""
    rate_limit = getattr(g, "rate_limit", None)
    if rate_limit:
        response.headers["X-RateLimit-Limit"] = str(rate_limit["limit"])
        response.headers["X-RateLimit-Remaining"] = str(rate_limit["remaining"])
        response.headers["X-RateLimit-Reset"] = str(rate_limit["reset"])
        if rate_limit["degraded"]:
            response.headers["X-RateLimit-Degraded"] = "redis-unavailable"
    return response


@app.route("/health")
def health():
    """Health check — deliberately not rate limited."""
    return jsonify({"status": "ok", "fail_mode": FAIL_MODE})


@app.route("/api/data")
def get_data():
    return jsonify({"message": "Here is your data!", "client": g.client_id,
                    "timestamp": time.time()})


@app.route("/api/search")
def search():
    return jsonify({"message": f"Search results for: {request.args.get('q', '')}",
                    "client": g.client_id, "results": ["result1", "result2"]})


@app.route("/api/premium")
def premium():
    return jsonify({"message": "Premium data access", "client": g.client_id})


if __name__ == "__main__":
    print(f"🚦 Rate-Limited API on port {FLASK_PORT}  (fail mode: {FAIL_MODE})")
    print(f"📡 Redis: {REDIS_HOST}:{REDIS_PORT}")
    app.run(host="0.0.0.0", port=FLASK_PORT, debug=False)
