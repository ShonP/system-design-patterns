# Lab verification tools

Three scripts for checking that the labs in this repo actually work. They need
no dependencies beyond the Python standard library, plus `docker` and `uv` on
your PATH for the ones that use them.

| Script | What it does | Needs Docker |
|--------|--------------|:------------:|
| `validate_labs.py` | Static checks over every lab. Fast (seconds). | only to lint compose files |
| `check_ports.py` | Says which labs would fail to start right now, and what is holding the port. | yes |
| `run_labs.py` | Really runs the labs: compose up → `uv sync` → execute every notebook → compose down. | yes |

## `validate_labs.py`

```bash
python tools/validate_labs.py                    # whole repo
python tools/validate_labs.py 01-foundations/caching
```

Catches the failure modes that silently rot a notebook repo:

- notebooks that are not valid JSON, or whose `source` lines lost their
  trailing newline (which mashes every line onto the previous one)
- Python cells that do not parse
- imports that are not declared in the lab's `pyproject.toml`
- a lab whose `project.name` collides with one of its own dependencies, which
  makes `uv sync` fail with *"depends on itself"*
- notebooks pinned to a Jupyter kernel name that is not installed, which
  raises `NoSuchKernel` the moment you open them
- invalid `docker-compose.yml`, or bind-mounts pointing at paths that do not exist
- labs whose notebooks talk to infrastructure ports but ship no compose file

Exits non-zero if it finds an error, so it works as a CI gate.

## `check_ports.py`

```bash
python tools/check_ports.py                      # whole repo
python tools/check_ports.py 01-foundations/cdn
```

Labs publish fixed host ports — 5432 for Postgres, 3000 for Grafana, 8000 for an
app. If something else on your machine already owns one, `docker compose up`
fails with a cryptic `Bind for 0.0.0.0:5432 failed: port is already allocated`.
This prints which lab, which port, and which container or process is holding it.

A local Postgres, a `next dev` server on 3000, or another lab you forgot to tear
down are the usual culprits.

## `run_labs.py`

```bash
python tools/run_labs.py 01-foundations/caching        # one lab
python tools/run_labs.py 01-foundations                # everything underneath
python tools/run_labs.py --all --no-docker             # only labs needing no containers
python tools/run_labs.py --all --json results.json     # the full sweep
```

For each lab it brings the Docker stack up (waiting for healthchecks), runs
`uv sync`, executes every notebook with nbconvert, and tears the stack down.
Executed copies go to a temp directory, so the notebooks in the repo are never
modified and stay free of committed output.

Labs are run **one at a time on purpose**: many publish the same host ports, so
running two concurrently makes them fail for reasons that have nothing to do
with the lab. A full `--all` sweep pulls a lot of images and takes hours; the
`--no-docker` subset finishes in a few minutes.

One-shot init containers (bucket creation, data seeding) exit 0 by design.
`docker compose up --wait` counts any exit as a failure, so the harness
re-checks the long-lived services before declaring a lab broken.

## Suggested order

```bash
python tools/validate_labs.py            # seconds -- catches most rot
python tools/check_ports.py              # seconds -- explains startup failures
python tools/run_labs.py --all --no-docker   # minutes
python tools/run_labs.py --all               # hours, full verification
```

## CI

`.github/workflows/validate-labs.yml` runs `validate_labs.py` over the whole repo
on every push and pull request, plus a four-lab execution smoke test that needs
no containers. The full `run_labs.py --all` sweep starts real infrastructure for
every lab and takes hours, so run that locally before a release rather than in CI.
