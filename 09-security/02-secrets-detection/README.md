# Lab 02 — Secrets Detection with Gitleaks & TruffleHog

## 🎯 What you'll learn

- How **secret-scanning** tools work (regex + entropy + verifiers)
- Use **Gitleaks** to scan a Git repo (working tree + full history)
- Use **TruffleHog** as a second opinion, with **live verification** of leaked credentials
- Plant fake secrets, detect them, and **purge them from git history**
- Wire **pre-commit hooks** so secrets never make it past your laptop
- Add a CI gate so secrets never make it past your branch

## 📋 Prerequisites

- Docker (Gitleaks and TruffleHog run as containers)
- `git` 2.30+
- ~200 MB disk for scanner images

## 🔧 Setup

This lab ships a **sample git repo** in `sample-repo/` that has fake secrets planted across multiple commits — exactly the situation you'll inherit in real life.

```bash
$ cd 02-secrets-detection
$ ./scripts/init-sample-repo.sh    # creates a git history with planted secrets across N commits
$ ls sample-repo/.git              # confirm it's a real repo now
```

The fake secrets follow the public **canary patterns** vendors recommend (e.g., `AKIAIOSFODNN7EXAMPLE`) so they trip detectors but **cannot be used** to authenticate to anything.

---

## 📝 Exercises

### Exercise 1 — Scan the working tree with Gitleaks

```bash
$ ./scripts/run-gitleaks.sh detect \
    --source sample-repo \
    --no-git \
    --report-path exercises/gitleaks-tree.json \
    --report-format json
$ jq 'length, .[0]' exercises/gitleaks-tree.json
```

> ✅ Expected: ≥ 5 findings. Each finding includes `RuleID`, `File`, `StartLine`, `Match`, `Secret`.

### Exercise 2 — Scan the full git history

The dangerous case: the secret is gone from `HEAD` but lives forever in `git log`.

```bash
$ ./scripts/run-gitleaks.sh detect \
    --source sample-repo \
    --report-path exercises/gitleaks-history.json \
    --report-format json
$ jq '[.[] | .Commit] | unique | length' exercises/gitleaks-history.json
```

> ✅ Expected: findings span **multiple commits**, including ones where the file has since been deleted.

**Why this matters:** removing a secret in a new commit doesn't remove it. Anyone who clones can still read it. You either rotate the credential (best) or rewrite history (`git filter-repo` / BFG) — covered in the challenge.

### Exercise 3 — Try TruffleHog (and verify findings)

TruffleHog's killer feature is **live verification** — it actually attempts to use the credential against the relevant API to tell you "this is a real, working AWS key" vs "this is just a string that looks like one."

```bash
$ ./scripts/run-trufflehog.sh git file:///workspace/sample-repo \
    --json \
    --no-update > exercises/trufflehog.json
$ jq -s '.[0]' exercises/trufflehog.json
```

> 💡 The fakes in this lab are **not** verifiable (they're public canaries) — TruffleHog will mark them `Verified: false`. In a real engagement that field is the difference between "ticket" and "incident."

### Exercise 4 — Custom Gitleaks rule

Imagine your company prefixes internal API tokens with `INT-`. Add a rule to catch them.

Open `exercises/gitleaks-custom.toml`:

```toml
title = "security-labs custom rules"

[extend]
useDefault = true

[[rules]]
id = "internal-api-token"
description = "Internal company API token (INT-...)"
regex  = '''INT-[A-Z0-9]{16,}'''
tags   = ["custom", "internal"]
```

Now plant one in `sample-repo/configs/internal.yaml` and rescan:

```bash
$ echo "api_token: INT-ABCDEFGHIJKLMNOP1234" >> sample-repo/configs/internal.yaml
$ ./scripts/run-gitleaks.sh detect \
    --source sample-repo --no-git \
    --config /workspace/exercises/gitleaks-custom.toml
```

> ✅ Expected: Gitleaks finds your custom pattern with `RuleID: internal-api-token`.

### Exercise 5 — Pre-commit hook (your real defensive layer)

Install [pre-commit](https://pre-commit.com/) and use the provided `.pre-commit-config.yaml`:

```bash
$ cd sample-repo
$ pip install --user pre-commit  # or: brew install pre-commit
$ cp ../exercises/.pre-commit-config.yaml .
$ pre-commit install
```

Try to commit a secret:

```bash
$ echo "AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" >> notes.txt
$ git add notes.txt
$ git commit -m "this should fail"
```

> ✅ Expected: commit is **blocked** by Gitleaks before it lands. This is the most valuable layer — it's your last chance before the secret is in history.

### Exercise 6 — Wire it into CI

Look at `exercises/.github-workflow-gitleaks.yml`. It's a drop-in GitHub Actions job that runs Gitleaks on every PR and fails the build on findings.

```yaml
- uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Copy it into a real repo's `.github/workflows/` to enable. (We can't run it in this lab without a real GitHub repo.)

### Exercise 7 — What to do when you find a real secret

There's a runbook in `exercises/INCIDENT-RUNBOOK.md`. The order matters: **rotate first, then clean up.** Many incidents are made worse by people frantically rewriting history before they revoke the credential.

---

## 💡 Key Concepts

| Concept                       | TL;DR                                                                                              |
|-------------------------------|----------------------------------------------------------------------------------------------------|
| **Regex detection**           | Fast, easy to extend, lots of false positives. Most rules are regex.                               |
| **Entropy detection**         | Catches generic high-entropy strings (random base64-looking blobs). Slower, noisy without regex.   |
| **Verification**              | TruffleHog probes the actual API (e.g., AWS STS GetCallerIdentity) to confirm the key works.       |
| **`.gitleaksignore`**         | Per-finding allowlist by fingerprint. Use sparingly. Real secrets need rotation, not allowlisting. |
| **Canary patterns**           | Strings vendors publish (`AKIA...EXAMPLE`) that test scanners without granting access.             |
| **History rewriting**         | `git filter-repo` (recommended) or BFG. Coordinated; everyone re-clones afterward.                 |
| **Defense in depth**          | (1) IDE plugin → (2) pre-commit → (3) CI scan → (4) push protection (GitHub) → (5) post-commit alerting. |

### Detection strategy stack

```text
              FAST                           SLOW              EXPENSIVE
        ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
files → │   regex     │→ │   entropy    │→ │  validators  │→ │   live verify    │
        └─────────────┘  └──────────────┘  └──────────────┘  └──────────────────┘
        (Gitleaks)       (Gitleaks)        (TruffleHog)      (TruffleHog --verify)
```

Use cheap layers everywhere. Use expensive layers in CI / nightly scans.

---

## 🏆 Challenge

1. **Purge a leaked secret from history.** Use [`git filter-repo`](https://github.com/newren/git-filter-repo) on `sample-repo` to remove `apps/web/config.json` from every commit. Verify with `gitleaks detect` that the secret is gone from history. Document your steps.
2. **Custom rule with allowlist.** Write a Gitleaks rule that catches `Bearer [A-Za-z0-9._-]+` but **allowlists** values inside `*.test.js` and `*.md` files. Confirm it doesn't false-positive on test fixtures.
3. **Multi-tool dedupe.** Run Gitleaks + TruffleHog and write a script that produces a single deduplicated list of findings keyed by `(commit, file, line)`.
4. **Push protection simulation.** Configure a server-side `pre-receive` hook on a bare repo (`sample-repo-bare.git`) that runs Gitleaks and rejects pushes containing secrets. Demonstrate it blocking a push.

---

## 📚 Further reading

- [Gitleaks docs](https://github.com/gitleaks/gitleaks) — especially the `config.toml` reference
- [TruffleHog docs](https://github.com/trufflesecurity/trufflehog) — see "Detectors" for the list of verifiable services
- [GitHub Push Protection](https://docs.github.com/en/code-security/secret-scanning/push-protection-for-repositories-and-organizations)
- [git-filter-repo](https://github.com/newren/git-filter-repo) — modern replacement for `filter-branch`
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- `research-report.md` §4.3 in this repo

➡️ Next: [Lab 03 — SAST / Code Scanning](../03-sast-code-scanning/)
