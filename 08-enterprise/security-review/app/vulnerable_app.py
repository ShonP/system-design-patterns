"""
🚨 INTENTIONALLY VULNERABLE Flask Application 🚨

This application contains DELIBERATE security vulnerabilities for educational purposes.
DO NOT deploy this to production. Each vulnerability is marked with a comment.

Used by the Jupyter notebooks to demonstrate:
- SQL Injection
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Server-Side Request Forgery (SSRF)
- Hardcoded secrets
- Broken authentication
"""

import os
import jwt
import hashlib
import bcrypt
import requests as http_requests
from datetime import datetime, timedelta, timezone
from flask import Flask, request, jsonify, render_template_string, redirect, make_response
import psycopg2
import redis

app = Flask(__name__)

# ============================================================
# 🚨 VULNERABILITY: Hardcoded secrets (Notebook 3 covers this)
# ============================================================
SECRET_KEY = "super-secret-key-12345"  # NEVER do this in production
DATABASE_URL = "postgresql://demo:demo@localhost:5432/security_demo"  # credentials in code
API_KEY = "sk-1234567890abcdef"  # API key in source code

# Database connection
def get_db():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        database=os.getenv("DB_NAME", "security_demo"),
        user=os.getenv("DB_USER", "demo"),
        password=os.getenv("DB_PASS", "demo"),
    )

def get_redis():
    return redis.Redis(
        host=os.getenv("REDIS_HOST", "localhost"),
        port=int(os.getenv("REDIS_PORT", "6379")),
        decode_responses=True,
    )


# ============================================================
# 🚨 VULNERABILITY 1: SQL Injection
# ============================================================

@app.route("/api/products/search")
def search_products_vulnerable():
    """VULNERABLE: User input directly concatenated into SQL query."""
    query = request.args.get("q", "")
    conn = get_db()
    cur = conn.cursor()

    # 🚨 BAD: String concatenation in SQL query
    sql = f"SELECT id, name, price FROM products WHERE name LIKE '%{query}%'"
    cur.execute(sql)

    products = [{"id": r[0], "name": r[1], "price": float(r[2])} for r in cur.fetchall()]
    cur.close()
    conn.close()
    return jsonify(products)


@app.route("/api/products/search/safe")
def search_products_safe():
    """FIXED: Uses parameterized queries to prevent SQL injection."""
    query = request.args.get("q", "")
    conn = get_db()
    cur = conn.cursor()

    # ✅ GOOD: Parameterized query — database driver handles escaping
    sql = "SELECT id, name, price FROM products WHERE name LIKE %s"
    cur.execute(sql, (f"%{query}%",))

    products = [{"id": r[0], "name": r[1], "price": float(r[2])} for r in cur.fetchall()]
    cur.close()
    conn.close()
    return jsonify(products)


# ============================================================
# 🚨 VULNERABILITY 2: Cross-Site Scripting (XSS)
# ============================================================

@app.route("/comments/<int:product_id>")
def show_comments_vulnerable(product_id):
    """VULNERABLE: User content rendered without escaping."""
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT u.username, c.content, c.created_at "
        "FROM comments c JOIN users u ON c.user_id = u.id "
        "WHERE c.product_id = %s ORDER BY c.created_at DESC",
        (product_id,)
    )
    comments = cur.fetchall()
    cur.close()
    conn.close()

    # 🚨 BAD: two bugs stacked on top of each other.
    #   (a) user content goes into HTML with no escaping        -> stored XSS
    #   (b) that same string is then COMPILED AS A JINJA TEMPLATE -> SSTI
    # (b) is the worse one: a comment containing {{ 7*7 }} is *evaluated on the
    # server*, which is a foothold for remote code execution, not just a popup.
    html = "<h2>Product Comments</h2>"
    for username, content, created_at in comments:
        html += f"<div><b>{username}</b>: {content} <small>({created_at})</small></div>"

    return render_template_string(html)  # 🚨 user data reaches the template compiler


@app.route("/comments/<int:product_id>/safe")
def show_comments_safe(product_id):
    """FIXED: User content is HTML-escaped before rendering."""
    from markupsafe import escape

    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT u.username, c.content, c.created_at "
        "FROM comments c JOIN users u ON c.user_id = u.id "
        "WHERE c.product_id = %s ORDER BY c.created_at DESC",
        (product_id,)
    )
    comments = cur.fetchall()
    cur.close()
    conn.close()

    # ✅ GOOD: escape all user-provided content...
    html = "<h2>Product Comments</h2>"
    for username, content, created_at in comments:
        html += (
            f"<div><b>{escape(username)}</b>: {escape(content)} "
            f"<small>({escape(str(created_at))})</small></div>"
        )

    # ✅ GOOD: ...and then hand the finished HTML straight to the browser.
    # escape() neutralises < > & " ' — it does NOT neutralise Jinja's {{ }} or
    # {% %}. Passing this string to render_template_string() would still compile
    # user content as a template (SSTI), so escaping alone would NOT be a fix.
    # Rule: user data is a template *variable*, never part of the template text.
    return make_response(html)


@app.route("/api/comments", methods=["POST"])
def add_comment():
    """Add a comment (used for XSS demos)."""
    data = request.json
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO comments (user_id, product_id, content) VALUES (%s, %s, %s) RETURNING id",
        (data["user_id"], data["product_id"], data["content"]),
    )
    comment_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"id": comment_id}), 201


# ============================================================
# 🚨 VULNERABILITY 3: CSRF (no token validation)
# ============================================================

@app.route("/api/transfer", methods=["POST"])
def transfer_vulnerable():
    """VULNERABLE: No CSRF token validation — any site can submit this form."""
    # NOTE: request.json raises 415 when the body is form-encoded, and a
    # cross-site <form> POST is *always* form-encoded. Use silent parsing so the
    # endpoint accepts the request shape a real CSRF attack actually sends.
    data = request.get_json(silent=True) or request.form
    from_user = data.get("from_user")
    to_user = data.get("to_user")
    amount = data.get("amount")

    # 🚨 BAD: No CSRF token check, no origin validation
    return jsonify({
        "status": "transferred",
        "from": from_user,
        "to": to_user,
        "amount": amount,
    })


@app.route("/api/transfer/safe", methods=["POST"])
def transfer_safe():
    """FIXED: Validates CSRF token and checks Origin header."""
    # ✅ GOOD: Check Origin/Referer header
    origin = request.headers.get("Origin", "")
    allowed_origins = ["http://localhost:5001"]
    if origin not in allowed_origins:
        return jsonify({"error": "Invalid origin"}), 403

    # ✅ GOOD: Validate CSRF token from header
    csrf_token = request.headers.get("X-CSRF-Token")
    r = get_redis()
    expected_token = r.get(f"csrf:{request.cookies.get('session_id')}")
    if not csrf_token or csrf_token != expected_token:
        return jsonify({"error": "Invalid CSRF token"}), 403

    data = request.get_json(silent=True) or request.form
    return jsonify({
        "status": "transferred",
        "from": data.get("from_user"),
        "to": data.get("to_user"),
        "amount": data.get("amount"),
    })


# ============================================================
# 🚨 VULNERABILITY 4: SSRF (Server-Side Request Forgery)
# ============================================================

@app.route("/api/fetch-url")
def fetch_url_vulnerable():
    """VULNERABLE: Fetches any URL the user provides, including internal services."""
    url = request.args.get("url", "")

    # 🚨 BAD: No URL validation — attacker can access internal services
    try:
        response = http_requests.get(url, timeout=5)
        return jsonify({
            "status_code": response.status_code,
            "content": response.text[:1000],
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/fetch-url/safe")
def fetch_url_safe():
    """FIXED: Validates URLs against an allowlist and blocks internal addresses."""
    import ipaddress
    from urllib.parse import urlparse

    url = request.args.get("url", "")

    # ✅ GOOD: Parse and validate the URL
    try:
        parsed = urlparse(url)
    except Exception:
        return jsonify({"error": "Invalid URL"}), 400

    # ✅ GOOD: Only allow HTTPS
    if parsed.scheme not in ("https",):
        return jsonify({"error": "Only HTTPS URLs are allowed"}), 400

    # ✅ GOOD: Block internal/private IP ranges
    try:
        import socket
        ip = socket.gethostbyname(parsed.hostname)
        if ipaddress.ip_address(ip).is_private:
            return jsonify({"error": "Internal addresses are not allowed"}), 403
    except Exception:
        return jsonify({"error": "Could not resolve hostname"}), 400

    # ✅ GOOD: Allowlist of permitted domains
    allowed_domains = ["api.github.com", "httpbin.org"]
    if parsed.hostname not in allowed_domains:
        return jsonify({"error": f"Domain not in allowlist: {parsed.hostname}"}), 403

    # ⚠️  HONEST LIMITATION: this is still not airtight. We resolve the hostname
    # once for the check and requests resolves it again for the fetch, so an
    # attacker controlling DNS can return a public IP to us and a private IP to
    # requests (DNS rebinding). Production fix: resolve once, pin the validated
    # IP, and connect to that IP with the Host header set — or put the fetch
    # behind an egress proxy that enforces the allowlist.

    try:
        # ✅ GOOD: do NOT follow redirects. Without this, an allowlisted host can
        # answer 302 -> http://169.254.169.254/ and every check above is bypassed,
        # because requests re-resolves and re-fetches the redirect target itself.
        response = http_requests.get(url, timeout=5, allow_redirects=False)
        return jsonify({
            "status_code": response.status_code,
            "content": response.text[:1000],
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ============================================================
# 🚨 VULNERABILITY 5: Broken Authentication
# ============================================================

@app.route("/api/login", methods=["POST"])
def login_vulnerable():
    """VULNERABLE: Weak JWT, no rate limiting, reveals user existence."""
    data = request.json
    username = data.get("username", "")
    password = data.get("password", "")

    conn = get_db()
    cur = conn.cursor()

    # 🚨 BAD: Reveals whether user exists (information disclosure)
    cur.execute("SELECT id, password_hash FROM users WHERE username = %s", (username,))
    user = cur.fetchone()
    cur.close()
    conn.close()

    if not user:
        return jsonify({"error": "User not found"}), 404  # 🚨 reveals user existence

    # 🚨 BAD: Also computes MD5 (weak hash) — but the seed data is bcrypt, so we
    # fall back to bcrypt for the actual comparison. The point is: even when the
    # password is WRONG we still need to reject it, and the JWT/rate-limit
    # weaknesses below remain.
    _md5_hash = hashlib.md5(password.encode()).hexdigest()  # noqa: F841 (weak hash demo)
    if not bcrypt.checkpw(password.encode(), user[1].encode()):
        return jsonify({"error": "Invalid password"}), 401  # 🚨 still leaks which field was wrong

    # 🚨 BAD: JWT with no expiration, weak secret
    token = jwt.encode(
        {"user_id": user[0], "username": username, "role": "admin"},  # 🚨 hardcoded role
        SECRET_KEY,
        algorithm="HS256",
    )
    return jsonify({"token": token})


# ✅ GOOD: a real bcrypt hash of a value nobody can log in with. Comparing
# against it makes the "no such user" path cost the same as the "wrong password"
# path, closing the timing side channel. Computed once at import.
_DUMMY_PASSWORD_HASH = bcrypt.hashpw(b"no-such-user", bcrypt.gensalt())


@app.route("/api/login/safe", methods=["POST"])
def login_safe():
    """FIXED: Proper password hashing, rate limiting via Redis, secure JWT."""
    data = request.json
    username = data.get("username", "")
    password = data.get("password", "")

    # ✅ GOOD: Rate limiting with Redis
    r = get_redis()
    ip = request.remote_addr
    attempts_key = f"login_attempts:{ip}"
    attempts = int(r.get(attempts_key) or 0)
    if attempts >= 5:
        return jsonify({"error": "Too many login attempts. Try again later."}), 429

    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, password_hash, role FROM users WHERE username = %s", (username,))
    user = cur.fetchone()
    cur.close()
    conn.close()

    # ✅ GOOD: same error message AND same amount of work whether the user
    # exists or not. Always run one bcrypt comparison — against the real hash if
    # we have one, against the dummy hash if we don't — so response time does not
    # leak which usernames are registered.
    stored_hash = user[1].encode() if user else _DUMMY_PASSWORD_HASH
    password_ok = bcrypt.checkpw(password.encode(), stored_hash)
    if not user or not password_ok:
        r.incr(attempts_key)
        r.expire(attempts_key, 900)  # 15-minute window
        return jsonify({"error": "Invalid credentials"}), 401

    # ✅ GOOD: Reset attempts on success
    r.delete(attempts_key)

    # ✅ GOOD: JWT with expiration, proper secret from env, real role from DB
    token = jwt.encode(
        {
            "user_id": user[0],
            "username": username,
            "role": user[2],
            "exp": datetime.now(timezone.utc) + timedelta(hours=1),
            "iat": datetime.now(timezone.utc),
        },
        os.getenv("JWT_SECRET", SECRET_KEY),
        algorithm="HS256",
    )
    return jsonify({"token": token})


# ============================================================
# 🚨 VULNERABILITY 6: Missing Security Headers
# ============================================================

@app.route("/page/profile")
def profile_page_vulnerable():
    """VULNERABLE: No security headers. Browser has no extra protection."""
    html = """
    <h1>My Profile</h1>
    <p>Welcome back!</p>
    <!-- imagine a rich page here -->
    """
    # 🚨 BAD: No Content-Security-Policy, no HSTS, no X-Frame-Options,
    # no X-Content-Type-Options. The browser is flying blind.
    return html


@app.route("/page/profile/safe")
def profile_page_safe():
    """FIXED: Returns recommended security headers."""
    html = """
    <h1>My Profile</h1>
    <p>Welcome back!</p>
    <!-- imagine a rich page here -->
    """
    response = make_response(html)
    # ✅ GOOD: Tell the browser which scripts/styles are allowed
    response.headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self'"
    # ✅ GOOD: Force HTTPS for future requests (only meaningful over HTTPS)
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    # ✅ GOOD: Block clickjacking via iframes
    response.headers["X-Frame-Options"] = "DENY"
    # ✅ GOOD: Prevent MIME sniffing
    response.headers["X-Content-Type-Options"] = "nosniff"
    # ✅ GOOD: Limit how much info the Referer header leaks
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    # ✅ GOOD: Disable powerful APIs the page doesn't need
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    return response


# ============================================================
# Utility endpoints
# ============================================================

@app.route("/health")
def health():
    return jsonify({"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()})


@app.route("/api/audit-log")
def get_audit_log():
    """View the audit log (for monitoring demos)."""
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT id, user_id, action, resource, ip_address, details, created_at "
        "FROM audit_log ORDER BY created_at DESC LIMIT 50"
    )
    logs = [
        {
            "id": r[0], "user_id": r[1], "action": r[2], "resource": r[3],
            "ip_address": r[4], "details": r[5], "created_at": str(r[6]),
        }
        for r in cur.fetchall()
    ]
    cur.close()
    conn.close()
    return jsonify(logs)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
