#!/usr/bin/env python3
"""Static checks across every lab in this repo. No Docker, no execution.

Catches the class of breakage that silently rots a notebook repo:
  * notebooks that are not valid JSON, or whose source lines lost their
    trailing newline (every line gets mashed onto the previous one)
  * Python cells that do not parse
  * imports that are not declared in the lab's pyproject.toml
  * docker-compose files that are invalid, or bind-mount paths that do not exist
  * notebooks pinned to a Jupyter kernel name that is not installed
  * labs whose notebooks talk to infrastructure ports with no compose file

Usage:
    python tools/validate_labs.py            # whole repo
    python tools/validate_labs.py 01-foundations/caching
"""
from __future__ import annotations

import ast
import json
import re
import subprocess
import sys
import tomllib
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# import name -> the distribution that provides it (or a parent that pulls it in)
IMPORT_TO_PKG = {
    "psycopg2": "psycopg2-binary", "psycopg": "psycopg", "redis": "redis",
    "kafka": "kafka-python", "confluent_kafka": "confluent-kafka",
    "pymongo": "pymongo", "cassandra": "cassandra-driver", "boto3": "boto3",
    "botocore": "boto3", "requests": "requests", "urllib3": "requests",
    "httpx": "httpx", "aiohttp": "aiohttp", "pandas": "pandas", "numpy": "numpy",
    "matplotlib": "matplotlib", "sqlalchemy": "sqlalchemy", "fastapi": "fastapi",
    "uvicorn": "uvicorn", "pydantic": "pydantic", "pydantic_settings": "pydantic-settings",
    "elasticsearch": "elasticsearch", "kazoo": "kazoo", "etcd3": "etcd3",
    "prometheus_client": "prometheus-client", "opentelemetry": "opentelemetry",
    "temporalio": "temporalio", "grpc": "grpcio", "grpc_tools": "grpcio-tools",
    "websockets": "websockets", "yaml": "pyyaml", "dotenv": "python-dotenv",
    "jwt": "pyjwt", "jose": "python-jose", "cryptography": "cryptography",
    "bcrypt": "bcrypt", "faker": "faker", "networkx": "networkx", "scipy": "scipy",
    "sklearn": "scikit-learn", "mmh3": "mmh3", "xxhash": "xxhash",
    "bitarray": "bitarray", "IPython": "ipython", "ipywidgets": "ipywidgets",
    "tabulate": "tabulate", "rich": "rich", "seaborn": "seaborn", "plotly": "plotly",
    "minio": "minio", "pika": "pika", "celery": "celery", "flask": "flask",
    "PIL": "pillow", "openai": "openai", "anthropic": "anthropic",
    "geopy": "geopy", "shapely": "shapely", "h3": "h3", "s2sphere": "s2sphere",
    "clickhouse_driver": "clickhouse-driver", "influxdb_client": "influxdb-client",
    "neo4j": "neo4j", "asyncpg": "asyncpg", "aiokafka": "aiokafka",
    "sortedcontainers": "sortedcontainers", "pytest": "pytest", "locust": "locust",
    "psutil": "psutil", "tenacity": "tenacity", "pybreaker": "pybreaker",
    "cachetools": "cachetools", "diskcache": "diskcache", "msgpack": "msgpack",
    "orjson": "orjson", "zstandard": "zstandard", "lz4": "lz4",
    "structlog": "structlog", "loguru": "loguru", "typer": "typer", "click": "click",
    "sseclient": "sseclient-py", "graphviz": "graphviz", "tqdm": "tqdm",
    "dateutil": "python-dateutil", "pytz": "pytz", "uuid6": "uuid6",
    "pyarrow": "pyarrow", "duckdb": "duckdb", "alembic": "alembic",
    "nest_asyncio": "nest-asyncio", "croniter": "croniter", "feedparser": "feedparser",
    "bs4": "beautifulsoup4", "lxml": "lxml", "jinja2": "jinja2", "docker": "docker",
    "nbformat": "nbformat", "pkg_resources": "setuptools",
}
STDLIB = set(sys.stdlib_module_names)
PY_CELL_MAGICS = {"%%time", "%%timeit", "%%capture", "%%prun", "%%debug"}
# A line magic looks like `!cmd` or `%cmd`. It is NOT a continuation line that
# merely begins with an operator -- `!= other` and `% width` are ordinary Python.
_MAGIC_LINE = re.compile(r"^\s*(?:!(?![=])\S|%{1,2}[A-Za-z_]|\?\S)")
INFRA_PORTS = {"5432", "6379", "9092", "2181", "8123", "9200", "27017", "9042"}


def python_source(src: str) -> str | None:
    """Return the Python part of a cell, or None if the cell is not Python."""
    lines = src.split("\n")
    first = next((l for l in lines if l.strip()), "")
    if first.strip().startswith("%%") and first.split()[0] not in PY_CELL_MAGICS:
        return None  # %%bash / %%writefile / %%html ...
    out, skip_cont = [], False
    for line in lines:
        s = line.strip()
        if skip_cont:
            skip_cont = s.endswith("\\")
            out.append("pass")
        elif _MAGIC_LINE.match(line):
            skip_cont = s.endswith("\\")
            out.append("pass")
        else:
            out.append(line)
    return "\n".join(out)


def top_level_imports(tree: ast.AST) -> set[str]:
    names: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            names.update(a.name.split(".")[0] for a in node.names)
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            names.add(node.module.split(".")[0])
    return names


def find_labs(root: Path) -> list[Path]:
    labs: set[Path] = set()
    for p in root.rglob("pyproject.toml"):
        if any(x in p.parts for x in (".git", ".venv")):
            continue
        labs.add(p.parent)
    for p in root.rglob("*.ipynb"):
        if any(x in p.parts for x in (".git", ".venv", ".ipynb_checkpoints")):
            continue
        labs.add(p.parent.parent if p.parent.name == "notebooks" else p.parent)
    return sorted(labs)


def check_lab(lab: Path, findings: dict[str, list[tuple[str, str]]]) -> None:
    rel = str(lab.relative_to(REPO))

    def add(sev: str, msg: str) -> None:
        findings[rel].append((sev, msg))

    notebooks = sorted(p for p in lab.rglob("*.ipynb")
                       if ".ipynb_checkpoints" not in p.parts and ".venv" not in p.parts)
    pyproject = lab / "pyproject.toml"
    composes = sorted(lab.glob("docker-compose*.yml")) + sorted(lab.glob("docker-compose*.yaml"))

    if not (lab / "README.md").exists():
        add("WARN", "no README.md")
    if notebooks and not pyproject.exists():
        add("ERROR", f"{len(notebooks)} notebooks but no pyproject.toml")

    declared: set[str] = set()
    if pyproject.exists():
        try:
            data = tomllib.loads(pyproject.read_text())
        except Exception as exc:
            add("ERROR", f"pyproject.toml does not parse: {exc}")
            data = {}
        project = data.get("project", {})
        for dep in project.get("dependencies", []) or []:
            m = re.match(r"^([A-Za-z0-9._-]+)", dep)
            if m:
                declared.add(m.group(1).lower().replace("_", "-"))
        name = (project.get("name") or "").lower().replace("_", "-")
        if name and name in declared:
            add("ERROR", f"project name '{name}' collides with a dependency of the same "
                         f"name -- `uv sync` fails with 'depends on itself'")

    used: set[str] = set()
    for nb in notebooks:
        try:
            doc = json.loads(nb.read_text())
        except Exception as exc:
            add("ERROR", f"{nb.name}: invalid JSON ({exc})")
            continue

        cells = doc.get("cells", [])
        if not cells:
            add("ERROR", f"{nb.name}: zero cells")
            continue

        kernel = doc.get("metadata", {}).get("kernelspec", {}).get("name")
        if kernel and kernel != "python3":
            add("ERROR", f"{nb.name}: pinned to kernel '{kernel}' -- opening it raises "
                         f"NoSuchKernel unless that kernel was registered globally")

        for cell in cells:
            src = cell.get("source")
            if isinstance(src, list) and len(src) > 1:
                nonl = sum(1 for l in src[:-1] if not l.endswith("\n"))
                if nonl:
                    add("ERROR", f"{nb.name}: {nonl} source lines lost their trailing "
                                 f"newline -- the code is mashed together")
                    break

        if not any(c.get("cell_type") == "markdown" for c in cells):
            add("WARN", f"{nb.name}: no markdown cells (no teaching text)")

        for i, cell in enumerate(c for c in cells if c.get("cell_type") == "code"):
            src = "".join(cell.get("source", []))
            if not src.strip():
                continue
            code = python_source(src)
            if code is None:
                continue
            try:
                used |= top_level_imports(ast.parse(code))
            except SyntaxError as exc:
                add("ERROR", f"{nb.name} code cell #{i}: SyntaxError line {exc.lineno}: {exc.msg}")

    if pyproject.exists():
        missing = []
        for imp in sorted(used):
            if imp in STDLIB or imp.startswith("_"):
                continue
            # generated at runtime by grpcio-tools / protoc inside the notebook
            if imp.endswith(("_pb2", "_pb2_grpc")):
                continue
            # a module that ships with the lab (servers/, app/, helpers next to the notebooks)
            if any(m for m in lab.rglob(f"{imp}.py") if ".venv" not in m.parts) or (lab / imp).is_dir():
                continue
            pkg = IMPORT_TO_PKG.get(imp)
            if pkg is None:
                missing.append(f"{imp} (unrecognised -- add it to IMPORT_TO_PKG if it is a real package)")
            elif pkg.lower() not in declared and not any(pkg.lower() in d for d in declared):
                missing.append(f"{imp} -> {pkg}")
        if missing:
            add("ERROR", "imported but not in pyproject dependencies: " + ", ".join(missing))

    for comp in composes:
        proc = subprocess.run(["docker", "compose", "-f", comp.name, "config", "-q"],
                              cwd=str(lab), capture_output=True, text=True)
        if proc.returncode != 0:
            add("ERROR", f"{comp.name}: invalid compose file: {proc.stderr.strip()[:200]}")
        for m in re.finditer(r"^\s*-\s+\./([^\s:]+):", comp.read_text(), re.M):
            if not (lab / m.group(1)).exists():
                add("ERROR", f"{comp.name}: bind-mounts ./{m.group(1)}, which does not exist")

    if notebooks and not composes:
        blob = " ".join(nb.read_text(errors="ignore") for nb in notebooks)
        hit = sorted({p for p in INFRA_PORTS if f"localhost:{p}" in blob})
        if hit:
            add("ERROR", f"notebooks connect to infra ports {hit} but the lab has no "
                         f"docker-compose.yml")


def main() -> int:
    targets = [REPO / a for a in sys.argv[1:]] or [REPO]
    findings: dict[str, list[tuple[str, str]]] = defaultdict(list)
    labs = [l for t in targets for l in find_labs(t)]
    for lab in labs:
        check_lab(lab, findings)

    errors = warnings = 0
    for rel in sorted(findings):
        items = findings[rel]
        if not items:
            continue
        print(f"\n{rel}")
        for sev, msg in items:
            print(f"  {sev}: {msg}")
            if sev == "ERROR":
                errors += 1
            else:
                warnings += 1

    print(f"\n{len(labs)} labs checked -- {errors} errors, {warnings} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
