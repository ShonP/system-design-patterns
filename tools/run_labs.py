#!/usr/bin/env python3
"""Execute every notebook in one or more labs, end to end, and report failures.

This is the harness used to verify the repo: it brings up each lab's Docker
stack, installs its dependencies with `uv`, executes every notebook with
nbconvert, and tears the stack down again. Executed copies are written to a
scratch directory so the notebooks in the repo stay clean.

Usage:
    python tools/run_labs.py 01-foundations/caching
    python tools/run_labs.py 01-foundations            # every lab underneath
    python tools/run_labs.py --all                     # the whole repo (slow)
    python tools/run_labs.py --all --no-docker         # only labs without compose

Exit code is non-zero if any lab failed.

Note: labs are run one at a time on purpose. Many publish the same host ports
(5432, 6379, 8000, ...), so running two at once makes them fail for reasons
that have nothing to do with the lab. Run `python tools/check_ports.py` first
if a stack refuses to start.
"""
from __future__ import annotations

import argparse
import json
import re
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = Path(tempfile.gettempdir()) / "system-design-labs-executed"


def run(cmd: list[str], cwd: Path, timeout: int) -> tuple[int, str, str]:
    try:
        proc = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, timeout=timeout)
        return proc.returncode, proc.stdout[-4000:], proc.stderr[-8000:]
    except subprocess.TimeoutExpired:
        return -9, "", f"timed out after {timeout}s"


def published_ports(compose_file: Path) -> list[str]:
    return sorted({m.group(1) for m in
                   re.finditer(r'^\s*-\s*"?(\d{2,5}):\d+', compose_file.read_text(), re.M)},
                  key=int)


def port_busy(port: str) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(0.3)
        return sock.connect_ex(("127.0.0.1", int(port))) == 0


def find_labs(root: Path) -> list[Path]:
    labs: set[Path] = set()
    for nb in root.rglob("*.ipynb"):
        if any(x in nb.parts for x in (".git", ".venv", ".ipynb_checkpoints")):
            continue
        labs.add(nb.parent.parent if nb.parent.name == "notebooks" else nb.parent)
    return sorted(labs)


def compose_up(lab: Path, compose: Path) -> tuple[bool, str]:
    taken = [p for p in published_ports(compose) if port_busy(p)]
    if taken:
        return False, f"host ports already in use: {', '.join(taken)} (see tools/check_ports.py)"

    run(["docker", "compose", "-f", compose.name, "down", "-v", "--remove-orphans"], lab, 180)
    # --build matters: several labs build an image from source in the repo
    # (a mini-SIEM, a deliberately vulnerable Flask app). Plain `up` reuses a
    # previously built image, so a source edit is silently not picked up and the
    # notebooks are verified against stale code.
    rc, _, err = run(["docker", "compose", "-f", compose.name, "up", "-d", "--build",
                      "--wait", "--wait-timeout", "300"], lab, 900)
    if rc == 0:
        return True, ""

    # One-shot init containers (bucket creation, data seeding) exit 0 on purpose,
    # but `--wait` counts any exit as a failure. Re-check the long-lived services.
    if "exited (0)" in err:
        ps = subprocess.run(["docker", "compose", "-f", compose.name, "ps", "--format",
                             "{{.Service}}|{{.State}}|{{.Health}}|{{.ExitCode}}"],
                            cwd=str(lab), capture_output=True, text=True)
        broken = []
        for line in ps.stdout.strip().split("\n"):
            parts = line.split("|")
            if len(parts) < 4:
                continue
            _, state, health, code = parts[:4]
            if state == "running" and health in ("", "healthy"):
                continue
            if state == "exited" and code == "0":
                continue
            broken.append(line)
        if not broken:
            return True, ""
        return False, err + "\nstill broken: " + "; ".join(broken)
    return False, err


def check_lab(lab: Path, use_docker: bool, nb_timeout: int) -> dict:
    rel = str(lab.relative_to(REPO))
    result = {"lab": rel, "setup": None, "notebooks": {}}
    started = time.time()

    composes = sorted(lab.glob("docker-compose*.yml")) + sorted(lab.glob("docker-compose*.yaml"))
    compose = composes[0] if composes else None

    if compose and use_docker:
        ok, err = compose_up(lab, compose)
        if not ok:
            result["setup"] = f"docker compose: {err[-600:]}"
            return result

    try:
        if (lab / "pyproject.toml").exists():
            rc, _, err = run(["uv", "sync", "--quiet"], lab, 900)
            if rc != 0:
                result["setup"] = f"uv sync: {err[-600:]}"
                return result
            run(["uv", "pip", "install", "-q", "nbconvert", "nbclient", "ipykernel"], lab, 600)

        out = OUT_DIR / rel.replace("/", "_")
        out.mkdir(parents=True, exist_ok=True)
        for nb in sorted(p for p in lab.rglob("*.ipynb")
                         if ".ipynb_checkpoints" not in p.parts and ".venv" not in p.parts):
            rc, _, err = run(["uv", "run", "--no-sync", "jupyter", "nbconvert",
                              "--to", "notebook", "--execute", "--output-dir", str(out),
                              f"--ExecutePreprocessor.timeout={nb_timeout}", str(nb)],
                             lab, nb_timeout * 4)
            result["notebooks"][str(nb.relative_to(lab))] = None if rc == 0 else err[-3000:]
    finally:
        if compose and use_docker:
            run(["docker", "compose", "-f", compose.name, "down", "-v", "--remove-orphans"],
                lab, 180)

    result["seconds"] = round(time.time() - started, 1)
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", help="lab or category paths, relative to the repo root")
    ap.add_argument("--all", action="store_true", help="run every lab in the repo")
    ap.add_argument("--no-docker", action="store_true",
                    help="skip labs that need docker-compose")
    ap.add_argument("--timeout", type=int, default=180,
                    help="per-cell timeout in seconds (default 180)")
    ap.add_argument("--json", metavar="FILE", help="also write results as JSON")
    args = ap.parse_args()

    if not args.paths and not args.all:
        ap.error("give at least one path, or --all")

    roots = [REPO] if args.all else [REPO / p for p in args.paths]
    labs = sorted({l for r in roots for l in find_labs(r)})

    results = []
    for lab in labs:
        rel = str(lab.relative_to(REPO))
        has_compose = bool(list(lab.glob("docker-compose*.y*ml")))
        if has_compose and args.no_docker:
            print(f"SKIP  {rel} (needs docker)")
            continue
        print(f"...   {rel}", flush=True)
        r = check_lab(lab, use_docker=not args.no_docker, nb_timeout=args.timeout)
        results.append(r)
        failed = [k for k, v in r["notebooks"].items() if v]
        if r["setup"]:
            print(f"FAIL  {rel} -- {r['setup'].splitlines()[0][:120]}")
        elif failed:
            print(f"FAIL  {rel} -- {len(failed)}/{len(r['notebooks'])} notebooks: {', '.join(failed)}")
        else:
            print(f"PASS  {rel} -- {len(r['notebooks'])} notebooks in {r.get('seconds')}s")

    if args.json:
        Path(args.json).write_text(json.dumps(results, indent=1))

    bad = [r for r in results if r["setup"] or any(r["notebooks"].values())]
    print(f"\n{len(results)} labs run, {len(bad)} failing. Executed copies in {OUT_DIR}")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
