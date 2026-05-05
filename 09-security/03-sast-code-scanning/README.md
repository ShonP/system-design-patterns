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
- Optional: `pip install semgrep` for native install

## 🔧 Setup

```bash
$ cd 03-sast-code-scanning
$ ls vulnerable-app/        # Python (Flask) and Node (Express) apps with deliberate flaws
$ ./scripts/run-semgrep.sh --version
```

The vulnerable apps are tiny on purpose — you should be able to read them top-to-bottom in a few minutes. This makes it possible to predict what Semgrep should find, then verify.

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

> ✅ Expected: findings for SQL injection, command injection, weak crypto, hardcoded credentials, deserialization, SSRF.

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

> 💡 More rulesets = more signal **and** more noise. In real codebases you tune which packs you want and which checks you allowlist.

### Exercise 3 — Read one finding end-to-end

Pick a finding for the SQL injection in `app.py`:

```bash
$ jq '.results[] | select(.check_id | test("sql"; "i")) | {id: .check_id, file: .path, line: .start.line, msg: .extra.message, fix: .extra.fix}' \
    exercises/semgrep-broad.json
```

Look at the offending line, read the rule's message, and fix it (commit your fix to your local branch). Rerun Semgrep — your finding should disappear.

### Exercise 4 — Write a custom rule (pattern)

Many companies forbid `eval()` outside of allow-listed sandboxes. Create `custom-rules/no-eval.yml`:

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

> ✅ Expected: matches `app.py` `eval(request.args.get(...))`.

### Exercise 5 — Custom rule with metavariable + filter

Catch any string concatenation into an SQL `execute(...)` — a classic SQLi pattern.

`custom-rules/no-sql-concat.yml`:

```yaml
rules:
  - id: no-sql-concat
    message: |
      String concatenation passed to .execute() is SQL injection.
      Use parameterized queries: cursor.execute(SQL, (param,))
    languages: [python]
    severity: ERROR
    patterns:
      - pattern-either:
          - pattern: $CUR.execute("..." + $X)
          - pattern: $CUR.execute(f"...{$X}...")
          - pattern: |
              $Q = "..." + $X
              ...
              $CUR.execute($Q)
```

Run it on the vulnerable app and confirm it catches every variant.

### Exercise 6 — Taint-mode rule (data-flow)

The pattern rules above are syntactic. **Taint mode** tracks data from `source` (e.g., `request.args`) to `sink` (e.g., `os.system`) across function boundaries.

`custom-rules/taint-cmdi.yml`:

```yaml
rules:
  - id: cmdi-from-request
    message: User-controlled data reaches os.system / subprocess.* — command injection.
    languages: [python]
    severity: ERROR
    mode: taint
    pattern-sources:
      - pattern: request.args.get(...)
      - pattern: request.form.get(...)
      - pattern: request.json[...]
    pattern-sinks:
      - pattern: os.system(...)
      - pattern: subprocess.$F($X, ..., shell=True)
      - pattern: subprocess.$F($X)
```

```bash
$ ./scripts/run-semgrep.sh --config custom-rules/taint-cmdi.yml vulnerable-app/python
```

> 💡 Taint mode is what catches "the secret got mixed into a log on line 123 because of input we got on line 8" — bugs that pattern matching misses.

### Exercise 7 — Bandit on the same Python code

```bash
$ ./scripts/run-bandit.sh -r vulnerable-app/python -f json -o exercises/bandit.json
$ jq '[.results[] | .test_id] | sort | unique' exercises/bandit.json
```

Compare what Bandit finds vs Semgrep:

- Bandit ships built-in checks for Python (B101–B7xx). Less flexible, but zero-config.
- Semgrep finds those + cross-language + custom + supports taint.
- In practice many shops run **both** in CI.

### Exercise 8 — Fix every finding

For each finding in `exercises/semgrep-broad.json`, apply the fix in `vulnerable-app/`. Suggested order:

1. Hardcoded credentials → env vars
2. SQL injection → parameterized queries
3. Command injection → `subprocess.run([...])` no `shell=True`
4. Weak crypto (`md5`/`sha1` for auth) → bcrypt/argon2
5. Insecure deserialization (`pickle.loads(request.body)`) → JSON
6. SSRF (`requests.get(user_url)`) → allowlist + URL parser
7. XSS (`render_template_string` with user input) → autoescape on, `{% autoescape %}`

After fixes, rerun `./scripts/run-semgrep.sh --config p/owasp-top-ten vulnerable-app/`. **Goal: zero findings.**

---

## 💡 Key Concepts

| Concept                       | TL;DR                                                                                        |
|-------------------------------|----------------------------------------------------------------------------------------------|
| **AST pattern matching**      | Semgrep parses code into an AST and matches *patterns* over the AST, not raw text.            |
| **Metavariables**             | `$X`, `$FOO` capture sub-expressions across rule arms, like regex backrefs but structural.    |
| **Taint mode**                | Track flow from sources (untrusted input) to sinks (dangerous APIs) across functions.        |
| **Severity / confidence**     | `ERROR/WARNING/INFO` × `HIGH/MEDIUM/LOW` confidence. Tune CI gates accordingly.              |
| **Autofix**                   | Some Semgrep rules ship `fix:` blocks. `semgrep --autofix` applies them.                     |
| **Allowlist**                 | `# nosemgrep: rule-id` line comment. Use sparingly — every allowlist is a future incident.   |
| **CWE**                       | Common Weakness Enumeration — the taxonomic ID for vuln *categories* (vs CVE for instances). |

### Where SAST fits

```text
                          ┌─ SAST ─┐
                          │        │  finds bugs in YOUR code (custom logic, business)
PRE-COMMIT  → CI  →  PR ─┤
                          │        │  finds bugs in DEPS  → SCA (lab 01)
                          └─ SCA ──┘  finds secrets       → secrets scan (lab 02)
                                       finds runtime bugs → DAST (lab 05)
```

SAST is the cheapest, fastest, most-coverage layer. It's also the noisiest. Tuning rulesets is part of the job.

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
- `research-report.md` §4.3 in this repo

➡️ Next: [Lab 04 — Container Security](../04-container-security/)
