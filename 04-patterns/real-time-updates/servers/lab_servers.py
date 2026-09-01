"""Start the lab's demo servers from inside a notebook.

Each notebook in this lab talks to a small FastAPI / websockets server that
lives in this folder. Previously you had to start them by hand in a second
terminal; if you forgot, the notebook printed a friendly "server is not
running" message and then crashed on the very next cell with a raw
ConnectionError.

`ensure_server(port)` makes each notebook self-contained: it starts the right
server as a background process (if it is not already listening), waits until
the port accepts connections, and shuts down anything it started when the
kernel exits. Running it twice is harmless -- an already-listening port is
left alone, so a server you started by hand still wins.
"""

from __future__ import annotations

import atexit
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SERVERS: dict[int, str] = {
    5001: "simple_polling_server.py",
    5002: "long_polling_server.py",
    5003: "sse_server.py",
    5004: "websocket_server.py",
    5005: "webhook_server.py",
}

SERVER_DIR = Path(__file__).resolve().parent
# port -> (process, open log file handle). The log is a real file rather than
# a pipe on purpose: uvicorn writes its own logs to stderr, and an OS pipe
# nobody ever reads fills up at ~64 KB and then blocks the server mid-write.
_started: dict[int, tuple[subprocess.Popen, "tempfile._TemporaryFileWrapper"]] = {}


def is_listening(port: int, host: str = "127.0.0.1", timeout: float = 0.3) -> bool:
    """True if something already accepts TCP connections on `port`."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        return sock.connect_ex((host, port)) == 0


def ensure_server(port: int, timeout: float = 30.0) -> str:
    """Make sure the demo server for `port` is up. Returns a status string."""
    if port not in SERVERS:
        raise ValueError(f"No lab server is defined for port {port}. Known: {sorted(SERVERS)}")

    if is_listening(port):
        return f"already running on port {port}"

    script = SERVER_DIR / SERVERS[port]
    if not script.exists():
        raise FileNotFoundError(f"Missing server script: {script}")

    # sys.executable is the notebook's own interpreter, i.e. this lab's .venv,
    # so the server gets the same dependencies the notebook has.
    log = tempfile.NamedTemporaryFile(
        prefix=f"lab_server_{port}_", suffix=".log", delete=False
    )
    proc = subprocess.Popen(
        [sys.executable, str(script)],
        cwd=str(SERVER_DIR),
        stdout=log,
        stderr=subprocess.STDOUT,
    )
    _started[port] = (proc, log)

    def _tail() -> str:
        try:
            return Path(log.name).read_text(errors="replace")[-800:]
        except OSError:
            return "(no output captured)"

    deadline = time.time() + timeout
    while time.time() < deadline:
        if is_listening(port):
            return f"started {SERVERS[port]} on port {port} (pid {proc.pid}, log {log.name})"
        if proc.poll() is not None:
            # Read the log BEFORE reaping -- _reap deletes it.
            out = _tail()
            code = proc.returncode
            _reap(port)
            raise RuntimeError(
                f"{SERVERS[port]} exited immediately (code {code}).\n"
                f"Did you run `uv sync`? output:\n{out}"
            )
        time.sleep(0.25)

    out = _tail()
    _reap(port)
    raise TimeoutError(
        f"{SERVERS[port]} did not start listening on port {port} within {timeout}s.\n"
        f"output:\n{out}"
    )


def _reap(port: int) -> None:
    """Stop one server we started and release every handle it owns."""
    entry = _started.pop(port, None)
    if entry is None:
        return
    proc, log = entry
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            # Without this second wait the child stays a zombie until the
            # kernel exits, and `is_listening` can still see its socket.
            proc.wait(timeout=5)
    try:
        log.close()
    except OSError:
        pass
    try:
        Path(log.name).unlink()
    except OSError:
        pass


def stop_all() -> None:
    """Terminate every server this module started (leaves manual ones alone)."""
    for port in list(_started):
        _reap(port)


atexit.register(stop_all)
