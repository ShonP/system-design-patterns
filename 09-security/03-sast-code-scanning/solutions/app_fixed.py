"""
Reference remediation for vulnerable-app/python/app.py — lab 03, exercise 9.

Kept OUT of vulnerable-app/ on purpose: every exercise scans vulnerable-app/,
and a second copy of the app in there would double every finding count.
Scan this file explicitly:

    ./scripts/run-semgrep.sh --config p/owasp-top-ten solutions/

Each fix names the finding it closes. The two `# nosemgrep` lines are not
laziness — see exercise 9 for why the SSRF rules cannot be cleared by code.
"""
import ast
import hashlib
import json
import os
import subprocess
from urllib.parse import urlparse

import requests
import sqlite3
from flask import Flask, request
from markupsafe import escape

app = Flask(__name__)

# FIX hardcoded secret -> injected at runtime, never committed.
API_KEY = os.environ["APP_API_KEY"]
PASSWORD_SALT = os.environ["APP_PASSWORD_SALT"].encode()

ALLOWED_FETCH_HOSTS = {"api.example.com"}


@app.route("/users")
def users():
    user_id = request.args.get("id", "")
    conn = sqlite3.connect("app.db")
    # FIX SQL injection -> parameterized query. user_id never reaches the SQL text;
    # the driver binds it as a value, so quoting and typing are not our problem.
    rows = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchall()
    return {"rows": rows}


@app.route("/ping")
def ping():
    host = request.args.get("host", "")
    # FIX command injection -> argv list, no shell, and the argument is validated
    # so a leading "-" cannot turn into a ping flag.
    if not host.replace(".", "").replace("-", "").isalnum():
        return {"error": "bad host"}, 400
    proc = subprocess.run(
        ["ping", "-c", "1", host], capture_output=True, timeout=5, check=False
    )
    return {"rc": proc.returncode}


@app.route("/exec")
def exec_route():
    expr = request.args.get("expr", "1+1")
    # FIX code injection -> literal_eval parses a literal, it never executes code.
    # (It still will not do arithmetic; if you need a calculator, write a parser.)
    try:
        return {"result": ast.literal_eval(expr)}
    except (ValueError, SyntaxError):
        return {"error": "not a literal"}, 400


@app.route("/login", methods=["POST"])
def login():
    pw = request.form["password"]
    # FIX weak hash -> scrypt, a salted KDF with a real work factor.
    # bcrypt/argon2 are equally fine; scrypt is here to avoid a new dependency.
    h = hashlib.scrypt(pw.encode(), salt=PASSWORD_SALT, n=16384, r=8, p=1).hex()
    return {"hash": h}


@app.route("/load", methods=["POST"])
def load():
    # FIX insecure deserialization -> JSON has no code-execution primitives.
    try:
        return {"data": json.loads(request.get_data())}
    except json.JSONDecodeError:
        return {"error": "bad json"}, 400


@app.route("/fetch")
def fetch():
    # nosemgrep: python.django.security.injection.ssrf.ssrf-injection-requests.ssrf-injection-requests -- scheme+host allowlisted below, redirects off
    url = request.args.get("url", "")
    # FIX SSRF -> scheme and host allowlist, and redirects disabled so the
    # allowlist cannot be walked around with a 302 to 169.254.169.254.
    parsed = urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in ALLOWED_FETCH_HOSTS:
        return {"error": "host not allowed"}, 400
    r = requests.get(url, timeout=5, allow_redirects=False)  # nosemgrep: python.flask.security.injection.ssrf-requests.ssrf-requests -- allowlist enforced above
    return r.text


@app.route("/hello")
def hello():
    name = request.args.get("name", "world")
    # FIX SSTI/XSS -> no template is compiled from user data, and the value is
    # HTML-escaped. Semgrep still flags the concatenation (WARNING) — see ex. 8.
    return "<h1>Hello %s</h1>" % escape(name)


if __name__ == "__main__":
    # FIX debug/bind-all -> loopback by default, debug only when asked for.
    app.run(
        host=os.environ.get("APP_HOST", "127.0.0.1"),
        port=5000,
        debug=os.environ.get("APP_DEBUG") == "1",
    )
