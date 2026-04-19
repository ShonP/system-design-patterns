"""Builds the lab's notebooks from inline cell definitions.

Run once from this folder:  uv run python _build_notebooks.py
We use this so the notebook sources stay readable in git diffs.
"""
from __future__ import annotations
import json, os, uuid, pathlib

HERE = pathlib.Path(__file__).parent

SETUP_MD = (
    "## 🛠️ Setup\n\n"
    "```bash\n"
    "cd 05-microservices/configuration-externalization\n"
    "uv sync\n"
    "```\n\n"
    "Select the `.venv` kernel in VS Code (top-right of the notebook). "
    "If it doesn't appear, reload the window: `Cmd+Shift+P` → **Reload Window**.\n"
)

def md(text: str):
    return {"cell_type": "markdown", "id": uuid.uuid4().hex[:8], "metadata": {}, "source": text.splitlines(keepends=True)}

def code(text: str):
    return {"cell_type": "code", "id": uuid.uuid4().hex[:8], "metadata": {}, "execution_count": None, "outputs": [], "source": text.splitlines(keepends=True)}

NB_META = {
    "kernelspec": {"display_name": ".venv", "language": "python", "name": "python3"},
    "language_info": {"name": "python", "version": "3.11"},
}

def write(name: str, cells: list):
    nb = {"cells": cells, "metadata": NB_META, "nbformat": 4, "nbformat_minor": 5}
    (HERE / name).write_text(json.dumps(nb, indent=1))

# ---------------------------------------------------------------------------
# Notebook 1 — Introduction: hardcoded → env vars → validated settings
# ---------------------------------------------------------------------------
nb1 = [
md("""# ⚙️ Notebook 1: Keep Config Out of the Binary

**Goal:** understand *why* we externalise configuration and see a clear
**bad → good → best** progression in Python.

- **Hardcoded** config means every change requires a new build & deploy.
- **Externalised** config means the *same binary* runs everywhere
  (dev / stage / prod) — the environment decides behaviour.

> 💡 **12-factor rule of thumb**: *if a value changes between deployments, it's config*.
"""),
md(SETUP_MD),
md("""## 🟥 BAD: hardcoded values

Everything is baked into the source. To run this in staging you'd have to
*edit the code and redeploy*. Scary.
"""),
code("""def bad_app():
    DB_HOST = "prod-db.internal"   # 😱 how do you run this in staging?
    RATE_LIMIT = 100
    DEBUG = False
    return f"connecting to {DB_HOST}, limit={RATE_LIMIT}, debug={DEBUG}"

print(bad_app())
"""),
md("""## 🟨 GOOD: read from environment variables

Environment variables are the simplest form of externalised config and
work everywhere (containers, CI, bare metal). We provide sensible defaults
for local development.
"""),
code("""import os

def good_app():
    db = os.environ.get("DB_HOST", "localhost")
    rl = int(os.environ.get("RATE_LIMIT", "10"))
    debug = os.environ.get("DEBUG", "false").lower() == "true"
    return f"connecting to {db}, limit={rl}, debug={debug}"

# Simulate prod vs staging *without rebuilding*.
os.environ["DB_HOST"] = "prod-db"; os.environ["RATE_LIMIT"] = "1000"; os.environ["DEBUG"] = "false"
print("prod :", good_app())

os.environ["DB_HOST"] = "stage-db"; os.environ["RATE_LIMIT"] = "50"; os.environ["DEBUG"] = "true"
print("stage:", good_app())
"""),
md("""### ⚠️ Problems with raw `os.environ`

1. **No validation** — `RATE_LIMIT=banana` crashes at first use, not at startup.
2. **No types** — everything is a string; you manually `int(...)` / parse bools.
3. **No documentation** — which variables does the app read? Nobody knows.
4. **No precedence** — what if you want *file < env < CLI* ordering?
"""),
md("""## 🟩 BEST: a typed, validated `Settings` object (pydantic)

We declare all config in *one place*, with types and defaults.
Pydantic validates on startup and gives a clear error if anything is wrong —
the service **fails fast** instead of crashing in production hours later.
"""),
code("""from pydantic import BaseModel, Field, ValidationError
import os

class Settings(BaseModel):
    db_host: str = Field(default="localhost", description="Database hostname")
    rate_limit: int = Field(default=10, ge=1, le=10_000, description="Requests/sec per user")
    debug: bool = Field(default=False)

    @classmethod
    def from_env(cls, env: dict[str, str] | None = None) -> "Settings":
        env = env if env is not None else os.environ
        # Simple precedence: defaults < env. A real app might also layer a config file.
        return cls(
            db_host=env.get("DB_HOST", cls.model_fields["db_host"].default),
            rate_limit=int(env.get("RATE_LIMIT", cls.model_fields["rate_limit"].default)),
            debug=env.get("DEBUG", "false").lower() == "true",
        )

prod = Settings.from_env({"DB_HOST": "prod-db", "RATE_LIMIT": "1000"})
print("prod :", prod)

# Validation catches bad values *at startup*:
try:
    Settings.from_env({"RATE_LIMIT": "999999"})
except ValidationError as e:
    print("startup rejected bad config:\\n", e)
"""),
md("""## 🗂️ Adding a file layer: precedence `defaults < file < env`

Real apps usually have a config file for the *shape* of the config and
environment variables for the few things that change per deployment
(secrets, hostnames). Environment variables **override** the file.
"""),
code("""import json, tempfile, os, pathlib

# Pretend this file ships with the app (checked into git, no secrets inside).
config_file = pathlib.Path(tempfile.gettempdir()) / "app.json"
config_file.write_text(json.dumps({"db_host": "file-db", "rate_limit": 25}))

def load_settings(path: pathlib.Path, env: dict[str, str]) -> Settings:
    data: dict = {}
    if path.exists():
        data.update(json.loads(path.read_text()))
    # env overrides file
    if "DB_HOST" in env:     data["db_host"] = env["DB_HOST"]
    if "RATE_LIMIT" in env:  data["rate_limit"] = int(env["RATE_LIMIT"])
    if "DEBUG" in env:       data["debug"] = env["DEBUG"].lower() == "true"
    return Settings(**data)

print("file only        :", load_settings(config_file, {}))
print("env overrides    :", load_settings(config_file, {"DB_HOST": "env-db"}))
print("env + file merged:", load_settings(config_file, {"RATE_LIMIT": "77"}))
"""),
md("""## 🧠 Takeaways

| Step | Where config lives | Validated? | Redeploy to change? |
|------|--------------------|-----------|---------------------|
| BAD  | in code            | n/a       | yes 😬              |
| GOOD | env vars           | no        | restart only        |
| BEST | env vars + file, typed `Settings` | yes ✅ | restart only |

Next notebook: **feature flags**, which let us change behaviour
*without even restarting*.
"""),
]
write("01_introduction.ipynb", nb1)

# ---------------------------------------------------------------------------
# Notebook 2 — Feature flags
# ---------------------------------------------------------------------------
nb2 = [
md("""# 🚩 Notebook 2: Feature Flags

A **feature flag** lets you toggle behaviour at runtime — *without a deploy*.

Common uses:
- Hide an unfinished feature behind `off`.
- Canary-release to 5% of users and watch metrics.
- Emergency **kill-switch** for a buggy feature.
- Per-environment toggles (e.g. `debug_mode` only in staging).
"""),
md(SETUP_MD),
md("""## 🟥 BAD: if-statements tied to deployment

Toggling `NEW_CHECKOUT = True` below requires a code change and a deploy —
exactly what feature flags exist to avoid.
"""),
code("""NEW_CHECKOUT = False  # flip and redeploy to enable 😬

def checkout(user_id: int):
    if NEW_CHECKOUT:
        return f"user {user_id} -> new checkout"
    return f"user {user_id} -> legacy checkout"

print(checkout(1))
"""),
md("""## 🟩 GOOD: a tiny `FlagStore`

In production you'd use a service like **LaunchDarkly**, **Unleash**, or
**Flagsmith**. The API is roughly the same: ask *"is flag X on for user Y?"*.
Here we fake one in-memory.
"""),
code("""import hashlib

class FlagStore:
    \"\"\"Pretend remote config service.

    Flag values can be:
      - bool           -> on/off for everyone
      - {\"percent\": N} -> stable N% rollout keyed by user_id
      - {\"users\": [..]} -> explicit allow-list
    \"\"\"
    def __init__(self, flags: dict):
        self.flags = dict(flags)

    def update(self, new: dict):
        self.flags.update(new)  # hot reload, no restart

    def enabled(self, flag: str, user_id: int | None = None) -> bool:
        f = self.flags.get(flag)
        if f is None or f is False:
            return False
        if f is True:
            return True
        if isinstance(f, dict):
            if user_id is not None and user_id in f.get("users", []):
                return True
            if "percent" in f and user_id is not None:
                h = int(hashlib.md5(f\"{flag}:{user_id}\".encode()).hexdigest(), 16) % 100
                return h < f[\"percent\"]
        return False

flags = FlagStore({
    "dark_mode": True,                 # everyone
    "new_checkout": {"percent": 20},   # 20% canary
    "experimental_search": False,      # off
    "beta_ui": {"users": [42, 99]},    # internal allow-list
})

for uid in range(6):
    print(
        f"user {uid}: dark_mode={flags.enabled('dark_mode', uid)} "
        f"new_checkout={flags.enabled('new_checkout', uid)} "
        f"beta_ui={flags.enabled('beta_ui', uid)}"
    )
"""),
md("""### 💡 Why a hash? (stable bucketing)

Using `md5(flag:user_id) % 100` means the *same* user always lands in the
same bucket — they don't flip between "on" and "off" on every request.
That's essential for consistent UX during a canary.
"""),
md("""## 🧯 Kill-switch without a redeploy

Ops sees a bug in `new_checkout` at 3 AM. Flip it off instantly:
"""),
code("""flags.update({"new_checkout": False})

print("after kill-switch:")
for uid in range(6):
    print(f"  user {uid}: new_checkout={flags.enabled('new_checkout', uid)}")
"""),
md("""## 🌍 Environment-aware flags

Typical pattern: the *same* code ships everywhere, but the flag store is
initialised differently per environment (via env vars from Notebook 1!).
"""),
code("""import os

def flags_for_env(env_name: str) -> FlagStore:
    base = {"dark_mode": True}
    if env_name == "staging":
        return FlagStore({**base, "experimental_search": True, "debug_panel": True})
    if env_name == "production":
        return FlagStore({**base, "experimental_search": {"percent": 5}})
    # dev / tests
    return FlagStore({**base, "experimental_search": True, "debug_panel": True})

for env in ("dev", "staging", "production"):
    fs = flags_for_env(env)
    print(env, "->", fs.flags)
"""),
md("""## 🆚 Environment variables vs feature flags

| | Environment var | Feature flag |
|--|--|--|
| Change requires deploy? | yes (restart) | no (hot reload) |
| Per-user targeting? | hard | easy |
| Good for secrets? | yes | **no** |
| Good for experiments? | no | yes |
| Typical change frequency | rare | often |

**Rule of thumb:** use env vars for *how the app is wired* (DB, ports, keys)
and feature flags for *what the product does* (UX variants, experiments).
"""),
md("""## ⚠️ Flag hygiene (real-world traps)

- **Flag debt**: dead flags accumulate forever. Set an owner + removal date.
- **Default off**: new flags should fail closed.
- **Test both states**: `on` *and* `off` need CI coverage.
- **Don't use flags for secrets** — they're usually readable by many people.
"""),
]
write("02_feature_flags.ipynb", nb2)

# ---------------------------------------------------------------------------
# Notebook 3 — Config server with hot reload
# ---------------------------------------------------------------------------
nb3 = [
md("""# 🏛️ Notebook 3: A Central Config Server (with hot reload)

So far each service reads its *own* env vars or config file. In a real
microservices system you often have **dozens** of services that need to
share settings (timeouts, feature flags, URLs, limits).

The **Config Server pattern**:

```
┌────────────┐    GET /config/orders     ┌────────────────┐
│ orders svc │ ────────────────────────► │ config server  │
│ pay svc    │ ────────────────────────► │  (central DB)  │
│ ship svc   │ ────────────────────────► │                │
└────────────┘                           └────────────────┘
```

Real examples: **Spring Cloud Config**, **HashiCorp Consul**,
**etcd**, **AWS AppConfig**, **Kubernetes ConfigMaps**.
"""),
md(SETUP_MD),
md("""## 🟩 A mini config server

We'll simulate a central server with a plain Python class and have two
"services" pull from it. No network — just to show the shape of the pattern.
"""),
code("""import time, threading

class ConfigServer:
    \"\"\"Central store. Versioned so clients can tell when config changes.\"\"\"
    def __init__(self):
        self._data: dict[str, dict] = {}
        self._version = 0
        self._lock = threading.Lock()

    def put(self, service: str, cfg: dict):
        with self._lock:
            self._data[service] = dict(cfg)
            self._version += 1
            print(f\"[server] {service} updated -> v{self._version}\")

    def get(self, service: str) -> tuple[int, dict]:
        with self._lock:
            return self._version, dict(self._data.get(service, {}))

server = ConfigServer()
server.put(\"orders\", {\"timeout_ms\": 500, \"retries\": 3})
server.put(\"payments\", {\"timeout_ms\": 2000, \"provider\": \"stripe\"})
print(server.get(\"orders\"))
print(server.get(\"payments\"))
"""),
md("""## 🔄 Hot reload from the client side

A service **polls** the server (or subscribes) and updates its in-memory
config when the version changes. No restart needed.
"""),
code("""class ServiceClient:
    def __init__(self, name: str, server: ConfigServer):
        self.name = name
        self.server = server
        self.version = -1
        self.config: dict = {}
        self.refresh()

    def refresh(self):
        v, cfg = self.server.get(self.name)
        if v != self.version:
            self.version = v
            self.config = cfg
            print(f\"[{self.name}] reloaded config v{v}: {cfg}\")

    def handle_request(self, req: str) -> str:
        self.refresh()  # a real app might poll every N seconds instead
        return f\"{self.name} handled {req!r} with timeout={self.config.get('timeout_ms')}ms\"

orders = ServiceClient(\"orders\", server)
print(orders.handle_request(\"buy\"))

# Ops bumps the timeout live — no redeploy:
server.put(\"orders\", {\"timeout_ms\": 1500, \"retries\": 5})
print(orders.handle_request(\"buy\"))
"""),
md("""## 🛟 What happens if the config server is down?

Rule: **a config outage must not take your services down.**
Clients should cache the last-known-good config and keep serving traffic.
"""),
code("""class ResilientClient(ServiceClient):
    def refresh(self):
        try:
            v, cfg = self.server.get(self.name)
            if v != self.version:
                self.version = v
                self.config = cfg
                print(f\"[{self.name}] reloaded v{v}\")
        except Exception as e:                  # e.g. network error
            print(f\"[{self.name}] config server down ({e}); using cached v{self.version}\")

# Break the server and make sure the client keeps working.
class BrokenServer:
    def get(self, service): raise ConnectionError(\"config server unreachable\")

rc = ResilientClient(\"orders\", server)   # fetch good config first
rc.server = BrokenServer()                # now simulate outage
print(rc.handle_request(\"buy\"))           # still uses cached config
"""),
md("""## 🏗️ Real-world shapes of this pattern

| Tool | Style | Notes |
|---|---|---|
| **Spring Cloud Config** | HTTP + git backend | Classic JVM microservices setup |
| **Consul / etcd** | KV store + watch | Used as a primitive by many systems |
| **Kubernetes ConfigMap/Secret** | Mounted as files or env | Restart pod *or* use a sidecar reloader |
| **AWS AppConfig / Parameter Store** | Managed service | Validation + staged rollout built-in |
| **LaunchDarkly / Unleash** | Flags-focused | Great for per-user targeting (see NB 2) |

## 🧠 Takeaways

- Centralising config scales *much* better than per-service env vars.
- Always **version** config so clients know when to reload.
- Clients must tolerate the server being **temporarily unreachable**.
- Combine with feature flags (NB 2) and secrets (NB 4) for a complete picture.
"""),
]
write("03_config_server.ipynb", nb3)

# ---------------------------------------------------------------------------
# Notebook 4 — Secrets management
# ---------------------------------------------------------------------------
nb4 = [
md("""# 🔐 Notebook 4: Secrets Management

Secrets are a **special kind of config** — things like DB passwords, API
keys, JWT signing keys, TLS private keys. Getting them wrong is how
companies end up on the front page of the news.

This notebook shows a clean **bad → good → best** for handling secrets
in a small Python service.
"""),
md(SETUP_MD),
md("""## 🟥 BAD: secrets in source code

Never do this. Once a secret is in git history it is effectively **public**
— rotating it is the only fix.
"""),
code("""# DO NOT DO THIS
DB_PASSWORD = \"hunter2-super-secret\"          # 😱 in git forever
STRIPE_KEY  = \"sk_live_51HxxYYzzAAbbCCddEE\"    # 😱

def connect():
    return f\"postgres://app:{DB_PASSWORD}@db/app\"

print(\"bad:\", connect())
"""),
md("""## 🟨 GOOD: load secrets from environment (or `.env` in dev)

The `.env` file stays **out of git** (`.gitignore` it). In production the
orchestrator (Kubernetes, ECS, systemd, ...) injects real secrets as
environment variables.
"""),
code("""import os, pathlib, tempfile

# Pretend this file lives at the project root and is gitignored.
dotenv = pathlib.Path(tempfile.gettempdir()) / \".env\"
dotenv.write_text(\"DB_PASSWORD=dev-password\\nSTRIPE_KEY=sk_test_123\\n\")

def load_dotenv(path: pathlib.Path) -> dict[str, str]:
    out = {}
    if not path.exists():
        return out
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith(\"#\") or \"=\" not in line:
            continue
        k, v = line.split(\"=\", 1)
        out[k.strip()] = v.strip()
    return out

# Real env always wins over .env so prod secrets aren't overridden by a file.
env = {**load_dotenv(dotenv), **os.environ}
print(\"loaded keys:\", sorted(k for k in env if k in {\"DB_PASSWORD\", \"STRIPE_KEY\"}))
"""),
md("""## 🙈 Never log secrets

The most common leak is not a hack — it's a stack trace or an INFO log
that accidentally prints the whole config object. Wrap secrets in a type
that **refuses** to render itself.
"""),
code("""class Secret:
    \"\"\"String-like wrapper that never leaks its value via repr/str/logs.\"\"\"
    __slots__ = (\"_value\",)

    def __init__(self, value: str):
        self._value = value

    def reveal(self) -> str:
        return self._value

    def __repr__(self) -> str:
        return \"Secret('***')\"
    __str__ = __repr__


db_password = Secret(env[\"DB_PASSWORD\"])
print(\"log line :\", f\"connecting with password={db_password}\")   # safe
print(\"actual   :\", db_password.reveal()[:3] + \"...\")             # only when needed
"""),
md("""## 🟩 BEST: a typed `Settings` with a `SecretStr`

Pydantic has `SecretStr` built-in — same idea as our `Secret` wrapper but
integrates cleanly with the `Settings` object from Notebook 1.
"""),
code("""from pydantic import BaseModel, SecretStr, Field

class AppSettings(BaseModel):
    db_host: str = \"localhost\"
    db_password: SecretStr
    stripe_key: SecretStr
    rate_limit: int = Field(default=10, ge=1)

settings = AppSettings(
    db_host=\"prod-db\",
    db_password=env[\"DB_PASSWORD\"],
    stripe_key=env[\"STRIPE_KEY\"],
)

print(\"repr (safe to log):\", settings)
print(\"masked pw         :\", settings.db_password)
print(\"actual pw (only at use):\", settings.db_password.get_secret_value())
"""),
md("""## 🏛️ Real secret stores (beyond env vars)

Environment variables are the lowest common denominator — fine for small
systems but they have drawbacks: visible in `/proc/<pid>/environ`, hard to
rotate, no audit log.

| Tool | What it gives you |
|---|---|
| **HashiCorp Vault** | Dynamic, short-lived secrets + audit log |
| **AWS Secrets Manager / SSM Parameter Store** | Managed KV with IAM + rotation |
| **GCP Secret Manager / Azure Key Vault** | Same, for their clouds |
| **Kubernetes Secrets** | Mounted as files/env in a pod (base64, *not* encrypted by default) |
| **SOPS / age** | Encrypt secrets *inside* git (keys stay in a KMS) |

The pattern is always the same: your **app reads an env var at startup**,
and something *outside* the app is responsible for putting the real value
there. Your code doesn't need to know which tool was used.
"""),
md("""## ✅ Secrets checklist

- [ ] No secrets in source code or in the Docker image.
- [ ] `.env*` files are gitignored (and scanned for with tools like `gitleaks`).
- [ ] Secrets come from env vars or a secret manager at runtime.
- [ ] Secrets are wrapped (`SecretStr` / `Secret`) so they don't end up in logs.
- [ ] Secrets can be **rotated** without a code change.
- [ ] Access is audited (who read which secret, when).
"""),
]
write("04_secrets.ipynb", nb4)

print("built notebooks:")
for p in sorted(HERE.glob("*.ipynb")):
    print(" -", p.name)
