"""
Intentionally vulnerable Flask app for security-labs lab 03.
DO NOT DEPLOY. Every line marked  # VULN: explains the issue Semgrep should find.
"""
import os
import sqlite3
import subprocess
import pickle
import hashlib
import requests
from flask import Flask, request, render_template_string

app = Flask(__name__)

API_KEY = "sk_live_EXAMPLE_FAKE_KEY_FOR_LAB"  # VULN: hardcoded secret

@app.route("/users")
def users():
    user_id = request.args.get("id", "")
    conn = sqlite3.connect("app.db")
    q = "SELECT * FROM users WHERE id = '" + user_id + "'"  # VULN: SQL injection
    rows = conn.execute(q).fetchall()
    return {"rows": rows}

@app.route("/ping")
def ping():
    host = request.args.get("host", "")
    out = os.system("ping -c 1 " + host)  # VULN: command injection
    return {"rc": out}

@app.route("/exec")
def exec_route():
    expr = request.args.get("expr", "1+1")
    return {"result": eval(expr)}  # VULN: code injection

@app.route("/login", methods=["POST"])
def login():
    pw = request.form["password"]
    h = hashlib.md5(pw.encode()).hexdigest()  # VULN: weak hash for auth
    return {"hash": h}

@app.route("/load", methods=["POST"])
def load():
    return {"data": str(pickle.loads(request.data))}  # VULN: insecure deserialization

@app.route("/fetch")
def fetch():
    url = request.args.get("url")
    r = requests.get(url, timeout=5)  # VULN: SSRF (no allowlist)
    return r.text

@app.route("/hello")
def hello():
    name = request.args.get("name", "world")
    tpl = "<h1>Hello %s</h1>" % name
    return render_template_string(tpl)  # VULN: SSTI / XSS

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)  # VULN: debug=True in prod
