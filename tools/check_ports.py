#!/usr/bin/env python3
"""Tell you, before you run `docker compose up`, which lab ports are taken.

Labs publish fixed host ports (5432 for Postgres, 3000 for Grafana, 8000 for an
app, ...). If something else on your machine already owns one, compose fails
with a cryptic

    Bind for 0.0.0.0:5432 failed: port is already allocated

and it is not obvious what is holding it. This prints the answer.

Usage:
    python tools/check_ports.py                    # every lab
    python tools/check_ports.py 01-foundations/cdn # just this one
"""
from __future__ import annotations

import re
import socket
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent


def published_ports(compose_file: Path) -> list[str]:
    text = compose_file.read_text()
    return sorted({m.group(1) for m in re.finditer(r'^\s*-\s*"?(\d{2,5}):\d+', text, re.M)},
                  key=int)


def in_use(port: str) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(0.3)
        return sock.connect_ex(("127.0.0.1", int(port))) == 0


def holders() -> dict[str, str]:
    """port -> a human description of what is listening."""
    out: dict[str, str] = {}
    try:
        docker = subprocess.run(["docker", "ps", "--format", "{{.Names}}|{{.Ports}}"],
                                capture_output=True, text=True, timeout=15).stdout
        for line in docker.strip().split("\n"):
            if not line:
                continue
            name, ports = line.split("|", 1)
            for m in re.finditer(r":(\d+)->", ports):
                out.setdefault(m.group(1), f"docker container '{name}'")
    except Exception:
        pass
    try:
        lsof = subprocess.run(["lsof", "-nP", "-iTCP", "-sTCP:LISTEN"],
                              capture_output=True, text=True, timeout=15).stdout
        for line in lsof.strip().split("\n")[1:]:
            parts = line.split()
            if len(parts) < 9:
                continue
            m = re.search(r":(\d+)$", parts[8])
            if m and m.group(1) not in out:
                out[m.group(1)] = f"process '{parts[0]}' (pid {parts[1]})"
    except Exception:
        pass
    return out


def main() -> int:
    targets = [REPO / a for a in sys.argv[1:]] or [REPO]
    who = holders()
    conflicts = 0
    checked = 0

    for target in targets:
        composes = sorted(p for p in target.rglob("docker-compose*.y*ml")
                          if ".git" not in p.parts and ".venv" not in p.parts)
        for comp in composes:
            lab = comp.parent.relative_to(REPO)
            ports = published_ports(comp)
            if not ports:
                continue
            checked += 1
            taken = [p for p in ports if in_use(p)]
            if taken:
                conflicts += 1
                print(f"\n{lab}")
                for p in taken:
                    print(f"  port {p} is already in use by {who.get(p, 'an unknown process')}")

    if conflicts:
        print(f"\n{conflicts} of {checked} labs would fail to start right now.")
        print("Free the port (stop the container or process above), or edit that lab's")
        print("docker-compose.yml to publish a different host port.")
    else:
        print(f"All {checked} labs' published ports are free.")
    return 1 if conflicts else 0


if __name__ == "__main__":
    raise SystemExit(main())
