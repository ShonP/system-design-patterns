# Lab 03 — SAST / Code Scanning with Semgrep

## 🎯 What you'll learn

- How **SAST** (Static Application Security Testing) finds bugs without running code
- Use **Semgrep** with the public registry (`p/security-audit`, `p/owasp-top-ten`) to scan a vulnerable Python and Node app
- Read findings: file/line/CWE/severity, and decide what to fix vs allowlist
- Write **custom Semgrep rules** in YAML — pattern, taint mode, metavariables
- Compare with **Bandit** (Python-specific) — when to use language-specific tools alongside Semgrep
- Wire SAST into a pre-commit hook and CI

## 📋 Prerequisites

- Docker
- ~500 MB disk for scanner + rules cache
- Optional native installs (faster, and what the wrappers prefer):
  `uv tool install semgrep` / `pip install semgrep`, and `uv tool install bandit`
- **Network access on first run.** `--config p/<name>` fetches the rule pack from the
  Semgrep registry and caches it in `~/.semgrep`. Fully offline runs need
  `--config <local-file>` — which is exactly what exercises 4–6 do.
- **No account needed.** Everything here runs on Semgrep OSS, logged out.
  `scripts/run-semgrep.sh` sets `SEMGREP_SEND_METRICS=off` for you (registry configs
  otherwise phone home); override with `SEMGREP_SEND_METRICS=auto` if you want the
  upstream default back.

> 📌 **Counts in this lab were measured on 2026-08-21** with Semgrep **1.174.0** (native)
> and cross-checked against the pinned `semgrep/semgrep:1.96.0` image, and Bandit
> **1.9.4**. Registry rule packs change under you, so treat exact numbers as a
> checkpoint, not a contract — but if yours is wildly different, look at *which* rules
> moved before you assume drift.

## 🔧 Setup

```bash
$ cd 03-sast-code-scanning
$ ls vulnerable-app/        # Python (Flask) and Node (Express) apps with deliberate flaws
$ ./scripts/run-semgrep.sh --version
```

The vulnerable apps are tiny on purpose — you should be able to read them top-to-bottom in a few minutes. This makes it possible to predict what Semgrep should find, then verify.

Both wrappers prefer a native binary and fall back to Docker. `docker-compose.yml` wires up
the same two images if you'd rather drive them that way — no ports, no long-running
containers, `--rm` cleans up after each scan:

```bash
$ docker compose --profile scan run --rm semgrep semgrep --config custom-rules/no-eval.yml vulnerable-app/python
$ docker compose --profile scan run --rm bandit  -r vulnerable-app/python
```

---

## 📝 Exercises

### Exercise 1 — Run the OWASP Top 10 ruleset

```bash
$ ./scripts/run-semgrep.sh \
    --config p/owasp-top-ten \
    --json --output exercises/semgrep-owasp.json \
    vulnerable-app/
$ jq '.results | length, .[0]' exercises/semgrep-owasp.json
```

Then a human-readable run:

```bash
$ ./scripts/run-semgrep.sh --config p/owasp-top-ten vulnerable-app/
```

> ✅ Expected: **17 findings — 7 ERROR, 10 WARNING.** (Measured 2026-08-21; the pinned
> `semgrep/semgrep:1.96.0` image gave 17 as well.) The shape:
> SQL injection (`app.py:21`), command injection (`app.py:27-28` — *three* rules for one
> bug), `eval` code injection (`app.py:33-34`), SSRF (`app.py:48-49`), weak MD5
> (`app.py:39`), SSTI/XSS (`app.py:55`), `debug=True` + bind-all (`app.py:59`), and on the
> Node side a hardcoded JWT secret, XSS, and an open redirect.
>
> ⚠️ Now notice what this pack **misses**, because that is the more useful half:
>
> - `pickle.loads(request.data)` on `app.py:44` — nothing. It shows up in exercise 2
>   under `p/security-audit`.
> - `exec("nslookup " + host)` on `server.js:13` — nothing. Also exercise 2.
> - `API_KEY = "sk_live_..."` on `app.py:15` — **nothing, in any pack in this lab.**
>   Verified against `p/owasp-top-ten`, `p/security-audit`, `p/python` and `p/secrets`.
>   Hardcoded-secret rules key off variable names and entropy heuristics, and this one
>   slips through all of them. Secret detection is lab 02's job, not SAST's.
>
> "The scanner was green" and "the code is clean" are different sentences.

### Exercise 2 — Add the security-audit & language packs

The OWASP set is a starter. The bigger nets are `p/security-audit`, `p/python`, `p/javascript`, `p/nodejsscan`.

```bash
$ ./scripts/run-semgrep.sh \
    --config p/security-audit \
    --config p/python \
    --config p/javascript \
    --severity ERROR --severity WARNING \
    --json --output exercises/semgrep-broad.json \
    vulnerable-app/
$ jq '[.results[] | .check_id] | sort | unique' exercises/semgrep-broad.json
```

> ✅ Expected: **23 findings — 10 ERROR, 13 WARNING** (measured 2026-08-21). That is the
> 17 from exercise 1 plus exactly six new ones: `pickle.loads` fires twice
> (`insecure-deserialization` ERROR + `avoid-pickle` WARNING), `render_template_string`
> picks up two more, `eval` picks up `eval-detected`, and `detect-child-process` finally
> catches the Node `exec()` that `p/owasp-top-ten` walked straight past.

> 💡 `--severity ERROR --severity WARNING` filters **nothing** in this run — this app
> produces no INFO findings at all. Drop the two flags and confirm you still get 23. On a
> real repo the INFO pile is where most of the volume lives, which is why the flags are in
> the command; here they are a no-op and it is worth knowing that before you trust them.

> 💡 More rulesets = more signal **and** more noise. In real codebases you tune which packs you want and which checks you allowlist.

`p/nodejsscan` is worth a look too — it finds 5 issues in `vulnerable-app/node` on its
own, including the hardcoded `JWT_SECRET` that `p/javascript` reports and
`p/security-audit` does not.

### Exercise 3 — Read one finding end-to-end

Pick a finding for the SQL injection in `app.py`:

```bash
$ jq '.results[] | select(.check_id | test("sql"; "i")) | {id: .check_id, file: .path, line: .start.line, msg: .extra.message, fix: .extra.fix}' \
    exercises/semgrep-broad.json
```

> ✅ Expected: exactly one match,
> `python.flask.security.injection.tainted-sql-string.tainted-sql-string` at
> `app.py:21`, with `"fix": null` — this rule ships no autofix, so you write the patch.

Look at the offending line, read the rule's message, and fix it (commit your fix to your
local branch). Replace the concatenation with
`conn.execute("SELECT * FROM users WHERE id = ?", (user_id,))` and rerun Semgrep — the
finding disappears. **Verify that**; a "fix" that still concatenates (e.g. one that only
adds `.replace("'", "")`) leaves the finding exactly where it was, which is the point.
`solutions/app_fixed.py` has the fixed version of every route if you want to compare.

### Exercise 4 — Read (and run) a custom rule (pattern)

Many companies forbid `eval()` outside of allow-listed sandboxes. The rule is already in
the repo at `custom-rules/no-eval.yml` — read it before you run it:

```yaml
rules:
  - id: no-eval
    message: |
      `eval()` executes arbitrary code. Use json.loads / safe parsers.
    languages: [python]
    severity: ERROR
    pattern: eval(...)
```

Run it:

```bash
$ ./scripts/run-semgrep.sh --config custom-rules/no-eval.yml vulnerable-app/
```

> ✅ Expected: **exactly 1 finding** — `app.py:34`, `return {"result": eval(expr)}`.
>
> Note what `pattern: eval(...)` is and is not. It matches a *call to a name* `eval`, so
> it will not match `self.eval(x)`, `model.eval()`, or `builtins.eval(x)`. That is
> deliberate — `model.eval()` in PyTorch is not a security bug, and a text-grep for
> `eval` would flag it. AST matching is why this rule is usable at all.

### Exercise 5 — Custom rule with metavariable + filter

Catch any string concatenation into an SQL `execute(...)` — a classic SQLi pattern.
See `custom-rules/no-sql-concat.yml`; it covers five spellings of the same bug:

```yaml
patterns:
  - pattern-either:
      # built inline, in the call
      - pattern: $CUR.execute("..." + $X)
      - pattern: $CUR.execute($X + "...")
      - pattern: $CUR.execute(f"...{$X}...")
      # built into a variable first, then executed
      - pattern: |
          $Q = <... "..." + $X ...>
          ...
          $CUR.execute($Q)
      - pattern: |
          $Q = f"...{$X}..."
          ...
          $CUR.execute($Q)
```

```bash
$ ./scripts/run-semgrep.sh --config custom-rules/no-sql-concat.yml vulnerable-app/python
```

> ✅ Expected: **exactly 1 finding**, `app.py:21-22` — the `/users` handler, matched by
> the fourth arm (build-then-execute), not the first: the concatenation and the
> `.execute()` are on different lines. Delete that arm, re-run, and watch it drop to 0.

**The `<... ... ...>` is doing real work, and it is the lesson.** The obvious way to write
that arm is `$Q = "..." + $X`, and that is what this rule used to say — and it found
*nothing*. Python parses `"SELECT ... '" + user_id + "'"` left-associatively as
`("SELECT ... '" + user_id) + "'"`, so the top-level left operand is a `BinOp`, not a
string literal, and `"..."` never binds. `<... ... ...>` is Semgrep's **deep expression**
operator: match this pattern *anywhere inside* the expression. That one change takes the
rule from 0/6 to 6/6 on the spellings below. Write them to `/tmp/sqli-spellings.py` and check:

```python
def a(u, cur): cur.execute("SELECT * FROM t WHERE id = '" + u + "'")
def b(u, cur): cur.execute("SELECT * FROM t WHERE id = " + u)
def c(u, cur): cur.execute(u + " FROM t")
def d(u, cur): cur.execute(f"SELECT * FROM t WHERE id = {u}")
def e(u, cur):
    q = "SELECT * FROM t WHERE id = '" + u + "'"
    cur.execute(q)
def f(u, cur):
    q = f"SELECT * FROM t WHERE id = {u}"
    cur.execute(q)
def safe(u, cur): cur.execute("SELECT * FROM t WHERE id = ?", (u,))   # must NOT match
```

```bash
$ ./scripts/run-semgrep.sh --config custom-rules/no-sql-concat.yml /tmp/sqli-spellings.py
```

> ✅ Expected: 6 findings — every function except `safe`.

**A pattern rule only finds the spellings you thought of**, and you will not think of all
of them. That is the entire motivation for exercise 6. (Semgrep's own answer to this is
`semgrep test`: put the good and bad spellings in a fixture file, annotate the bad lines
with `# ruleid: no-sql-concat`, and let CI tell you when you broke your own rule.)

### Exercise 6 — Taint-mode rule (data-flow)

The pattern rules above are syntactic. **Taint mode** tracks data from `source` (e.g.
`request.args`) to `sink` (e.g. `os.system`) through assignments, and stops at anything
you declare a **sanitizer**. A taint rule has three parts and skipping the third is the
usual reason people stop trusting one:

```yaml
rules:
  - id: cmdi-from-request
    languages: [python]
    severity: ERROR
    mode: taint
    pattern-sources:
      - pattern: request.args.get(...)
      - pattern: request.form.get(...)
      - pattern: request.form[...]
      - pattern: request.json[...]
    pattern-sanitizers:          # <- without these the rule invents false positives
      - pattern: shlex.quote(...)
      - pattern: int(...)
      - pattern: re.fullmatch(...)
    pattern-sinks:
      - pattern: os.system(...)
      - pattern: subprocess.$F($X, ..., shell=True)
      - patterns:                # subprocess.run(a + b) with no shell= is still a smell
          - pattern: subprocess.$F($X)
          - metavariable-pattern:
              metavariable: $X
              pattern: "$_ + $_"
```

```bash
$ ./scripts/run-semgrep.sh --config custom-rules/taint-cmdi.yml vulnerable-app/python
```

> ✅ Expected: **exactly 1 finding** — `app.py:28`, `os.system("ping -c 1 " + host)`.

Now prove to yourself that both of the interesting halves behave. Write this to
`/tmp/taint-demo.py` and scan it:

```python
import os, shlex, subprocess
from flask import Flask, request
app = Flask(__name__)

def run_it(cmd):
    os.system(cmd)                                  # sink, one call away

@app.route("/a")
def a():
    host = request.args.get("host", "")
    run_it("ping -c 1 " + host)                     # tainted, but via a helper
    return "ok"

@app.route("/b")
def b():
    host = request.args.get("host", "")
    os.system("ping -c 1 " + shlex.quote(host))     # sanitized
    return "ok"
```

> ✅ Expected: **0 findings** — and only one of those two zeroes is good news.
>
> `/b` is a true negative: `shlex.quote` is in `pattern-sanitizers`, so the taint stops
> there. Delete the `pattern-sanitizers:` block and re-run — `/b` now reports, and you
> have manufactured a false positive out of correctly-written code. That is how a rule
> loses its audience.
>
> `/a` is a **false negative**, and an important one. Semgrep OSS taint tracking is
> **intraprocedural**: it follows data within a function body, not across function
> boundaries. Interprocedural and cross-file taint are Semgrep Pro engine features
> (`semgrep --pro`, which requires a logged-in account and is out of scope here).
> So "extract the dangerous call into a helper" silently clears this rule without fixing
> anything. Any claim that OSS taint mode follows data "across function boundaries" is
> wrong, and believing it is how a scanner becomes a rubber stamp.

> 💡 Within a function, taint mode is still what catches "the secret got mixed into a log
> on line 123 because of input we got on line 8" — bugs pattern matching misses.

### Exercise 7 — Bandit on the same Python code

```bash
$ mkdir -p exercises
$ ./scripts/run-bandit.sh -r vulnerable-app/python -f json -o exercises/bandit.json
$ jq -r '.results[] | "\(.test_id) \(.issue_severity)/\(.issue_confidence) line \(.line_number) \(.test_name)"' \
    exercises/bandit.json | sort
```

> ✅ Expected: **exactly 9 findings** (measured 2026-08-21, Bandit 1.9.4 — same 9 from the
> `ghcr.io/pycqa/bandit/bandit` image). Exact IDs shift between Bandit releases:
>
> ```
> B104 MEDIUM/MEDIUM line 59 hardcoded_bind_all_interfaces
> B201 HIGH/MEDIUM   line 59 flask_debug_true
> B301 MEDIUM/HIGH   line 44 blacklist                        (pickle)
> B307 MEDIUM/HIGH   line 34 blacklist                        (eval)
> B324 HIGH/HIGH     line 39 hashlib                          (md5)
> B403 LOW/HIGH      line  8 blacklist                        (import pickle)
> B404 LOW/HIGH      line  7 blacklist                        (import subprocess)
> B605 HIGH/HIGH     line 28 start_process_with_a_shell
> B608 MEDIUM/LOW    line 21 hardcoded_sql_expressions
> ```
>
> Three IDs people expect here and do **not** get, all for good reasons worth knowing:
> **B102** (`exec_used`) — there is no `exec()` in this app, only `eval()`;
> **B113** (`request_without_timeout`) — `requests.get(url, timeout=5)` already has one,
> so the SSRF on line 49 draws no Bandit finding at all;
> **B607** (`start_process_with_partial_path`) — it fires on `subprocess` calls with a
> bare command name, so it appears in the *fixed* version (`solutions/app_fixed.py`) and
> not in the vulnerable one. A finding that appears when you fix the code is a normal and
> deeply annoying part of this job.

Now look at `issue_confidence`, and look specifically at **B608 MEDIUM/LOW** — the SQL
injection on line 21. Bandit is one of the few tools that publishes its own uncertainty,
and the temptation is to read `LOW` confidence as "probably nothing". Here the single
lowest-confidence finding in the report is the most serious bug in the file. Semgrep's
`tainted-sql-string` calls the same line an ERROR.

The honest version of the heuristic: severity × confidence tells you what to read **first**,
not what to ignore. `LOW` confidence means *the tool* is unsure, which is a statement about
the tool, not about your code.

Note also B403/B404 — "you imported `pickle`", "you imported `subprocess`". Both are
`LOW/HIGH`: high confidence you did it, low severity because importing a module is not a
vulnerability. These are the findings you tune out of a gate.

Compare what Bandit finds vs Semgrep:

- Bandit ships built-in checks for Python (B101–B7xx). Less flexible, but zero-config.
- Semgrep finds those + cross-language + custom + supports taint.
- In practice many shops run **both** in CI.

### Exercise 8 — Triage before you fix

Before touching code, split `exercises/semgrep-broad.json` into piles. Do this by hand —
it is the skill the tool cannot give you:

| Pile | What it means | Real example from this run |
|---|---|---|
| **True positive, reachable** | Attacker-controlled input reaches the dangerous call | `app.py:28` `os.system("ping -c 1 " + host)` |
| **True positive, not reachable** | Real bad practice, no path from untrusted input | `app.py:59` `debug-enabled` + `avoid_app_run_with_bad_host` — both sit under `if __name__ == "__main__"`, which never executes under gunicorn |
| **Duplicate** | Several rules, one bug, one fix | `app.py:55` draws three rules; the `os.system` on 27–28 draws three more. 23 findings, 12 distinct bugs |
| **Wrong-framework** | Right bug, rule written for a stack you don't use | four `python.django.security.*` hits in a Flask app. Harmless here — but a Django rule on Flask code is a coin flip |
| **False positive** | The rule matched syntax that is not the bug | see below — you have to make one, because this app is too small to contain one |

```bash
# How much of the wall is even ERROR severity?  -> 10 ERROR, 13 WARNING
$ jq -r '.results[] | .extra.severity' exercises/semgrep-broad.json | sort | uniq -c
# Which LINES attract the most rules? (duplicate noise, and the cheapest thing to fix)
$ jq -r '.results[] | "\(.path):\(.start.line)"' exercises/semgrep-broad.json \
    | sort | uniq -c | sort -rn | head
```

> 💡 Do **not** bother with `.check_id | sort | uniq -c | sort -rn` on this file — every
> rule fires exactly once, so the output is a flat list of 1s. That query is the right one
> on a real repo (find the rule with 400 hits and decide whether it earns them) and a
> misleading one here. Knowing which of your queries are degenerate on your sample data is
> part of not fooling yourself.

**Now produce a false positive on purpose**, with the lab's own rule. Exercise 5's
`no-sql-concat` matches `$CUR.execute(...)` — it has no idea whether `$CUR` is a database
cursor. Write this to `/tmp/not-sql.py`:

```python
# Not a database cursor anywhere in this file.
def build(executor, base):
    executor.execute(base + "/run")

def sched(scheduler, name):
    cmd = "job-" + name
    scheduler.execute(cmd)
```

```bash
$ ./scripts/run-semgrep.sh --config custom-rules/no-sql-concat.yml /tmp/not-sql.py
```

> ✅ Expected: **2 findings, both false positives.** `ThreadPoolExecutor`,
> `sqlalchemy.Engine`, Selenium drivers and half the job schedulers on PyPI all expose an
> `.execute()`. Sit with that number: this rule is 6/6 on real SQLi *and* fires on
> perfectly good code, on the same day, and you cannot tune one without the other.
>
> Your options, in the order a team usually reaches for them:
> 1. **Narrow the rule** — require `$CUR` to come from a `connect()`/`cursor()` call, or
>    restrict the rule to `paths:` that contain your data layer.
> 2. **Suppress the instance** — `# nosemgrep: no-sql-concat -- executor is a thread pool`.
> 3. **Delete the rule.** If it has produced ten false positives and zero real bugs, it is
>    costing you more than it returns.

Triage decisions have to be written down where the next reader hits them. A `nosemgrep`
without a reason is indistinguishable from someone silencing a real bug at 5pm.

**The triage burden is the actual cost of SAST.** A 2% false-positive rate on a 500k-line
repo is still hundreds of tickets. Teams that succeed with SAST do three things: run
`--severity ERROR` in the blocking gate and everything else in a report, diff against a
baseline so only *new* findings block (`--baseline-ref origin/main`), and delete rules that
have produced ten false positives and zero real bugs. A rule nobody trusts is worse than no
rule — it teaches developers that the gate is noise.

### Exercise 9 — Fix, then rescan

For each finding in `exercises/semgrep-broad.json`, apply the fix in `vulnerable-app/`. Suggested order:

1. Hardcoded credentials → env vars
2. SQL injection → parameterized queries
3. Command injection → `subprocess.run([...])` no `shell=True`
4. Weak crypto (`md5`/`sha1` for auth) → scrypt/bcrypt/argon2
5. Insecure deserialization (`pickle.loads(request.data)`) → JSON
6. SSRF (`requests.get(user_url)`) → scheme + host allowlist, `allow_redirects=False`
7. XSS / SSTI (`render_template_string` with user input) → don't compile user data into a
   template at all; escape the value instead

Count before you start, so the loop has a number:

```bash
$ ./scripts/run-semgrep.sh --config p/owasp-top-ten --json vulnerable-app/ \
    | jq '[.results[] | select(.extra.severity=="ERROR")] | length'   # baseline: 7
$ ./scripts/run-semgrep.sh --config p/owasp-top-ten --json vulnerable-app/ \
    | jq '.results | length'                                          # baseline: 17
```

Fix, then run exactly the same command again.

> ✅ Goal: **zero ERROR-severity findings from `p/owasp-top-ten`.** Not zero findings
> overall — `p/security-audit` includes audit-grade rules that fire on patterns which are
> fine in context, and chasing those to zero is how teams learn to hate the tool.

A worked reference lives in **`solutions/app_fixed.py`** — every route fixed, every fix
annotated. It is deliberately *outside* `vulnerable-app/` so it does not double the counts
in exercises 1–7. Scan it and compare against your own attempt:

```bash
$ ./scripts/run-semgrep.sh --config p/owasp-top-ten solutions/
```

> ✅ Measured 2026-08-21: **17 findings / 7 ERROR → 3 findings / 0 ERROR.** Bandit over the
> same file goes **9 → 3**, all three `LOW` severity. The broad exercise-2 config goes
> **23 → 3**.

Two things in that reference solution are worth more than the rest of the exercise:

**1. The SSRF findings cannot be cleared by writing correct code.** Add a scheme check,
add a hostname allowlist, set `allow_redirects=False` — a genuinely correct fix — and
`ssrf-requests` still fires, because the tainted string still reaches `requests.get()` and
the rule does not recognise your allowlist as a sanitizer. Rewriting the handler to look up
a *fixed* URL from a dict keyed by user input does not help either; the taint follows the
index. Verify that yourself before you accept it. So the last two findings come off with
suppressions, not with code:

```python
# nosemgrep: python.django.security.injection.ssrf.ssrf-injection-requests.ssrf-injection-requests -- scheme+host allowlisted below, redirects off
url = request.args.get("url", "")
...
r = requests.get(url, timeout=5, allow_redirects=False)  # nosemgrep: python.flask.security.injection.ssrf-requests.ssrf-requests -- allowlist enforced above
```

**Placement is not obvious and gets this wrong constantly:** `# nosemgrep` applies to the
line it is on, or the line immediately above the finding's **start** line. For a taint
finding the start line is the **source**, not the sink — which is why the Django-flavoured
rule above has to be silenced up at the `request.args.get(...)`, seven lines away from the
`requests.get()` it is complaining about. Put it next to the sink and it does nothing, and
you will believe you suppressed something you did not. Text after the rule ID is ignored by
Semgrep, so `-- <reason>` is free and should be mandatory: a `nosemgrep` without a reason
is indistinguishable from someone silencing a real bug at 5pm.

**2. Three WARNINGs survive on the fixed `/hello`, and all three are false positives.**
`"<h1>Hello %s</h1>" % escape(name)` is safe — `markupsafe.escape` is exactly the fix — but
`raw-html-format`, `raw-html-concat` and `directly-returned-format-string` do not model it.
This is the residue exercise 8 was preparing you for: at the end of a competent remediation
you are not at zero, you are at "zero blocking, and a documented reason for everything
left". Teams that insist on a literal zero get there by deleting rules, and the ones they
delete are rarely the useless ones.

---

## 💡 Key Concepts

| Concept                       | TL;DR                                                                                        |
|-------------------------------|----------------------------------------------------------------------------------------------|
| **AST pattern matching**      | Semgrep parses code into an AST and matches *patterns* over the AST, not raw text.            |
| **Metavariables**             | `$X`, `$FOO` capture sub-expressions across rule arms, like regex backrefs but structural.    |
| **Taint mode**                | Track flow from sources (untrusted input) to sinks (dangerous APIs), stopping at sanitizers. **Semgrep OSS is intraprocedural**; cross-function/cross-file taint is the Pro engine. |
| **Severity / confidence**     | `ERROR/WARNING/INFO` × `HIGH/MEDIUM/LOW` confidence. Tune CI gates accordingly.              |
| **Autofix**                   | Some Semgrep rules ship `fix:` blocks. `semgrep --autofix` applies them.                     |
| **Allowlist**                 | `# nosemgrep: rule-id -- reason` on the finding's line, or the line above its **start** line (for taint findings that is the *source*). Use sparingly — every allowlist is a future incident. |
| **CWE**                       | Common Weakness Enumeration — the taxonomic ID for vuln *categories* (vs CVE for instances). |

### SAST vs DAST vs SCA vs IAST

The four get used interchangeably in job ads and they are not interchangeable at all:

| | Sees | Needs | Finds | Misses | This repo |
|---|---|---|---|---|---|
| **SAST** | Your source / AST | Nothing running | Injection, crypto misuse, logic patterns — **before** the code merges | Anything that depends on config, deployment or runtime state. Cannot tell if a path is reachable in production. Weaker at secrets than it looks: none of this lab's packs find `app.py`'s `API_KEY` | lab 03 |
| **SCA** | Your dependency manifest / lock file / SBOM | A lock file or built artifact | Known CVEs in third-party code | Bugs in *your* code; also over-reports, since a vulnerable package ≠ a reachable vulnerable function | lab 01 |
| **DAST** | HTTP requests and responses | The app **running** | Missing headers, auth/session flaws, injection it can actually trigger, deployment mistakes | Anything not reachable from the crawled surface; anything behind auth it can't perform. No idea which line of code is at fault | lab 05 |
| **IAST** | Instrumented runtime — an agent inside the process during tests | An agent + a test suite that exercises the app | Real data-flow with real values: confirms the sink was reached with tainted input, and names the line | Only covers code your tests actually exercise. Language-specific agents, runtime overhead, commercial-heavy tool space | not covered here |

The important pairing: **SAST tells you where the bug is but not whether it matters; DAST
tells you it matters but not where it is. IAST is the attempt to get both at once**, at the
cost of needing an agent in the process and good test coverage. RASP is the same
instrumentation used to *block* at runtime rather than to report.

```text
                          ┌─ SAST ─┐  finds bugs in YOUR code (lab 03)
PRE-COMMIT  → CI  →  PR ─┤─ SCA ───┤  finds bugs in OTHER people's code (lab 01)
                          │─ secrets│  finds credentials (lab 02)
                          └─ DAST ──┘  finds bugs the running system exhibits (lab 05)
```

SAST is the cheapest, fastest, broadest-coverage layer. It's also the noisiest. Tuning rulesets is part of the job.

---

## 🏆 Challenge

1. **Reachable-only filter.** Write a Semgrep rule that flags `pickle.loads(...)` only when the argument flows from an HTTP handler.
2. **Per-team rule pack.** Build `custom-rules/team-payments.yml` with 3 rules specific to a payments service: forbid logging credit-card patterns, forbid `Decimal(float)`, forbid `eval` on amount strings.
3. **CI integration.** Write a GitHub Actions workflow that fails the PR on any new ERROR-severity Semgrep finding **introduced in the diff** (use `--baseline-ref origin/main`).
4. **CodeQL comparison.** Pick the SQL injection in `app.py`. Find or write a CodeQL query that detects it. Compare ergonomics with Semgrep.

---

## 📚 Further reading

- [Semgrep registry](https://semgrep.dev/r) — browse community rules; great way to learn rule patterns
- [Semgrep rule syntax](https://semgrep.dev/docs/writing-rules/rule-syntax/)
- [Taint tracking](https://semgrep.dev/docs/writing-rules/data-flow/taint-mode/)
- [Bandit docs](https://bandit.readthedocs.io/)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Semgrep: managing false positives](https://semgrep.dev/docs/writing-rules/testing-rules/) — write test cases for your rules

➡️ Next: [Lab 04 — Container Security](../04-container-security/)
