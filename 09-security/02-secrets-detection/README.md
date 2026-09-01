# Lab 02 — Secrets Detection with Gitleaks & TruffleHog

## 🎯 What you'll learn

- How **secret-scanning** tools work (regex + entropy + verifiers)
- Use **Gitleaks** to scan a Git repo (working tree + full history)
- Use **TruffleHog** as a second opinion, with **live verification** of leaked credentials
- Understand why **rotation, not deletion, is the fix** — and why purging history does not un-leak anything
- Wire **pre-commit hooks** so secrets never make it past your laptop
- Add a CI gate so secrets never make it past your branch

## 📋 Prerequisites

- Docker — the `scripts/run-*.sh` wrappers use a native `gitleaks` / `trufflehog` binary if
  you have one on `PATH`, and fall back to the pinned container otherwise
- `git` 2.30+
- `pre-commit` for exercise 5 (`brew install pre-commit`, or `pip install --user pre-commit`)
- ~200 MB disk for scanner images (gitleaks 78 MB + trufflehog 105 MB)

## 🔧 Setup

This lab ships a **sample git repo** in `sample-repo/` that has fake secrets planted across multiple commits — exactly the situation you'll inherit in real life.

```bash
$ cd 02-secrets-detection
$ ./scripts/init-sample-repo.sh    # creates a git history with planted secrets across N commits
$ ls sample-repo/.git              # confirm it's a real repo now
```

The planted values are generated fresh on every run of the script, or are vendor-published
test values, shaped exactly like the real thing. They authenticate to nothing. Because they
are generated rather than committed, your values differ from everyone else's — and from your
own on the next run, so don't memorise them between exercises.

> 🪤 **Why not use the famous canaries?** `apps/web/config.json` also contains AWS's
> documentation example key, `AKIAIOSFODNN7EXAMPLE`. Watch for it in exercise 1: it is
> **not** reported. Gitleaks (and most other scanners) allowlist the well-known
> documentation placeholders precisely so they don't page you over a README. A lab built
> entirely out of canaries would "work" while teaching you nothing about detection — and
> would hide the far more interesting failure mode, which is a real-looking secret the
> tool's regex happens not to match.

### A note on the command names

Gitleaks split its scanning verbs in **v8.19.0**: `gitleaks git <repo>` scans commit history,
`gitleaks dir <path>` scans files on disk (the old `detect --no-git`). The original
`gitleaks detect` was deprecated and has since been **removed** — it does not exist in 8.30.
This lab uses the current `git` / `dir` spelling throughout; if you find `gitleaks detect`
in a blog post, that post predates August 2024. (`gitleaks protect --staged`, the old
pre-commit spelling, still runs in 8.30 as an undocumented alias — but the hook you install
in exercise 5 uses the current `gitleaks git --pre-commit --staged`.)

---

## 📝 Exercises

### Exercise 1 — Scan the working tree with Gitleaks

```bash
$ ./scripts/run-gitleaks.sh dir sample-repo \
    --report-path exercises/gitleaks-tree.json \
    --report-format json
$ jq -r '.[] | "\(.RuleID)\t\(.File):\(.StartLine)"' exercises/gitleaks-tree.json
```

> ✅ Expected (gitleaks 8.30, default config): **4 findings**
>
> ```text
> aws-access-token    sample-repo/apps/web/config.json:3
> generic-api-key     sample-repo/apps/web/config.json:4
> slack-webhook-url   sample-repo/apps/api/notify.js:1
> github-pat          sample-repo/scripts/release.sh:2
> ```
>
> Each finding carries `RuleID`, `File`, `StartLine`, `Match`, `Secret`, `Entropy` and a
> `Fingerprint` (the stable ID you would put in `.gitleaksignore`).
>
> Gitleaks does not guarantee an order — the four rows come back in a different sequence on
> different versions. The rule IDs and locations are what you compare. Measured 2026-08-21
> with gitleaks 8.30.1 (native) and with the pinned `zricethezav/gitleaks:v8.30.1` image:
> both report the same four.

**Now find what is missing.** Open `apps/web/config.json`: it contains *four* AWS-looking
strings, and only two were reported. The `_docs.example_*` pair is AWS's published
documentation key, which the default config allowlists. Two lessons in one file:

- Detection is a **denylist of shapes plus an allowlist of known-fakes**. Both halves are
  guesses, and both halves are wrong sometimes.
- A determined leak can dodge the regexes entirely (base64 the key, split it across two
  variables, put it in a binary). Secret scanning raises the cost of leaking; it does not
  make leaking impossible. Which is why exercise 5 (pre-commit) and rotation discipline
  matter more than any single rule pack.

### Exercise 2 — Scan the full git history

The dangerous case: the secret is gone from `HEAD` but lives forever in `git log`.

```bash
$ ./scripts/run-gitleaks.sh git sample-repo \
    --report-path exercises/gitleaks-history.json \
    --report-format json
$ jq -r '.[] | "\(.RuleID)\t\(.File)\t\(.Commit[0:8])"' exercises/gitleaks-history.json
$ jq '[.[] | .Commit] | unique | length' exercises/gitleaks-history.json
```

> ✅ Expected: **7 findings across 4 commits** — the 4 from the working tree, plus three
> more (`stripe-access-token`, `sendgrid-api-token`, `generic-api-key`) from
> `.env.production`, **a file that does not exist at HEAD**. Commit 3 added it; commit 4
> deleted it; the blob is still in the object database and in every clone.
>
> Check the second half yourself: `git -C sample-repo ls-files` does not list
> `.env.production`, and exercise 1's working-tree scan never mentioned it. Three secrets
> that no amount of looking at the checkout will ever show you.

**Why this matters — the single most important idea in this lab:**

> A secret is compromised the moment it is pushed. Not when someone finds it, not when it
> appears in a scan report. **Rotation is the fix. Deletion is not a fix, and neither is
> rewriting history.**

Rewriting history (`git filter-repo`, BFG) does not un-leak a secret. By the time you run it:

- every clone, fork and CI cache still has the old objects;
- GitHub keeps unreachable objects reachable via the events API and PR refs for a while,
  and forks keep them indefinitely;
- credential-harvesting bots scrape public pushes within **seconds** — the measured
  time-to-first-use of a leaked AWS key is minutes, not days.

History rewriting is *hygiene you do after rotating*, so the next person to read the repo
doesn't re-leak it. It is never the response to the incident. Exercise 7 and
`exercises/INCIDENT-RUNBOOK.md` put the steps in the right order.

### Exercise 3 — Try TruffleHog (and verify findings)

TruffleHog's killer feature is **live verification** — it actually attempts to use the credential against the relevant API to tell you "this is a real, working AWS key" vs "this is just a string that looks like one."

```bash
# Docker path (the wrapper mounts the lab dir at /workspace):
$ ./scripts/run-trufflehog.sh git file:///workspace/sample-repo --json --no-update \
    > exercises/trufflehog.json

# If you installed trufflehog natively, there is no /workspace -- use an absolute local path:
$ ./scripts/run-trufflehog.sh git "file://$(pwd)/sample-repo" --json --no-update \
    > exercises/trufflehog.json

$ jq -s 'length, (.[0] | {detector: .DetectorName, verified: .Verified, file: .SourceMetadata})' \
    exercises/trufflehog.json
```

> The wrapper prefers a native binary and falls back to Docker, so the path you pass has to
> be valid in whichever one runs. This is the one place in these labs where that leaks.

> ✅ Expected: **6 results, 0 verified** (trufflehog 3.97.0): `AWS` in
> `apps/web/config.json`, `Github` in `scripts/release.sh`, `SlackWebhook` in
> `apps/api/notify.js`, and `Postgres`, `Stripe`, `SendGrid` in `.env.production`.
> TruffleHog scans history by default, which is why the deleted `.env.production` shows up
> without you asking for it.
>
> `0 verified` is the number to look at. TruffleHog's distinguishing feature is that it
> *calls the provider* to see whether a credential still works. Every value here is
> generated from `/dev/urandom`, so all six come back unverified — which is exactly what a
> rotated credential looks like, and exactly what a live one would not.

**The two tools disagree, and that is the point.** TruffleHog catches the Postgres
connection string on line 1 of `.env.production` that Gitleaks walks straight past; Gitleaks
catches the `JWT_SECRET` on line 3 that TruffleHog never mentions.

TruffleHog is organised around detectors for services it knows how to *verify*, and nothing
verifies a JWT signing secret. Neither tool is a superset of the other — which is why
challenge 3 asks you to merge their output rather than pick a winner.

> 🪤 **This lab used to report 5, and the missing one was a lesson in the wrong thing.**
> The Slack webhook was previously a hardcoded value whose team ID was mixed-case
> (`TgB2m4KcQ`). Real Slack team and channel IDs are uppercase, TruffleHog's detector
> matches accordingly, and so the tool "missed" a webhook that was really just malformed.
> The README drew a conclusion about scanner coverage from what was actually a typo in the
> fixture. Now that the value is generated in the correct shape, TruffleHog finds it.
>
> The general lesson is worth more than the specific one: **when you seed test secrets,
> a fixture that is subtly the wrong shape teaches you a scanner limitation that does not
> exist.** Check that your planted values match the real format before you conclude
> anything from what a scanner did or did not report.

> 💡 Every planted value here is fake, so TruffleHog marks them all `Verified: false`.
> In a real engagement that one field is the difference between "ticket" and "incident" —
> but note the asymmetry: `Verified: true` is proof you have a live incident, while
> `Verified: false` is **not** proof of safety. It can mean the key is real but scoped
> away from the probe endpoint, the service was unreachable, or TruffleHog has no detector
> for that vendor. Unverified findings still get rotated.

**Careful with `--results`.** TruffleHog sorts findings into `verified`, `unverified`
(detector matched, the API said no) and `unknown` (the verification attempt *errored* —
DNS failure, timeout, 500). Those last two are different things, and the widely copy-pasted
CI snippet `--results=verified,unknown` keeps only the first and the third:

```bash
$ ./scripts/run-trufflehog.sh git file:///workspace/sample-repo --json --no-update \
    --results=verified,unknown | jq -s length      # -> 1
$ ./scripts/run-trufflehog.sh git file:///workspace/sample-repo --json --no-update \
    --results=verified,unverified,unknown | jq -s length   # -> 5
```

The single survivor is the Postgres finding, and only because `db.internal` does not
resolve, so its verification *errored* into `unknown`. The four secrets that were cleanly
unverified — AWS, GitHub, Stripe, SendGrid — are dropped on the floor. A gate written that
way reports "clean" on a repo full of secrets. `exercises/.github-workflow-gitleaks.yml`
therefore passes all three. If you want the genuinely low-noise gate, that is
`--results=verified` (or `--only-verified`) — and you should be honest with yourself that
you have chosen to ignore everything the verifier could not reach.

> `--results` is a recent flag: absent from 3.83.7, present in 3.97.0 (both checked). On a
> build that rejects it, the equivalents are `--only-verified` and the default (everything).

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

# ...the file carries a second rule, company-jwt-prefix, as a worked example.
```

Now plant one in `sample-repo/configs/internal.yaml` and rescan:

```bash
$ echo "api_token: INT-ABCDEFGHIJKLMNOP1234" >> sample-repo/configs/internal.yaml
$ ./scripts/run-gitleaks.sh dir sample-repo \
    --config exercises/gitleaks-custom.toml \
    --report-path exercises/gitleaks-custom.json --report-format json
$ jq -r '.[].RuleID' exercises/gitleaks-custom.json
```

> ✅ Expected: **5 findings** — the 4 from exercise 1 plus `internal-api-token`.
> Use a path relative to the lab directory (not `/workspace/...`): the Docker wrapper sets
> `-w /workspace`, so relative paths resolve correctly in both the native and Docker cases.

> 🔍 A wrinkle worth noticing: that token is high-entropy enough that the **default**
> `generic-api-key` rule catches it too — scan `internal.yaml` without `--config` and you
> will see it reported anyway. With the custom config you get one finding per location, under
> the more specific rule. Custom rules mostly buy you *attribution and precision*
> ("this is one of ours, here is the runbook"), not raw coverage.

Leave `configs/internal.yaml` in place for now — exercise 8 makes you clean it up, which is
the whole point of that exercise.

`[extend] useDefault = true` is what keeps the built-in rules; drop that line and your
config *replaces* the default rule pack instead of adding to it — a classic way to
accidentally turn off every detector you had.

### Exercise 5 — Pre-commit hook (your real defensive layer)

Install [pre-commit](https://pre-commit.com/) and use the provided `.pre-commit-config.yaml`:

```bash
$ cd sample-repo
$ pip install --user pre-commit  # or: brew install pre-commit
$ cp ../exercises/.pre-commit-config.yaml .
$ pre-commit install
```

The first commit after this is slow: pre-commit builds Gitleaks from source into its cache.
Subsequent commits cost milliseconds.

First, try to commit the *documentation* key from exercise 1:

```bash
$ echo "AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" >> notes.txt
$ git add notes.txt
$ git commit -m "this should fail"
```

> ⚠️ Expected: `Detect hardcoded secrets...Passed` — **the commit lands.** That is the
> exercise-1 allowlist biting you from the other side: the hook is Gitleaks, so it ignores
> exactly the strings Gitleaks ignores. A pre-commit hook is not a proof of absence, and
> "the hook was green" is not a defence. Undo it before continuing:
>
> ```bash
> $ git reset --hard HEAD~1 && rm -f notes.txt
> ```

Now try a key the detector actually believes:

```bash
$ echo "AWS_ACCESS_KEY_ID=AKIA6QW3ZB2XNRTVKD5M" >> notes.txt
$ git add notes.txt
$ git commit -m "this should fail"
```

> ✅ Expected: the commit is **blocked** — `Detect hardcoded secrets...Failed`, exit code 1,
> and a redacted finding (`RuleID: aws-access-token`, `File: notes.txt`, `Line: 1`). Confirm
> nothing landed with `git log --oneline -1`. This is the most valuable layer — your last
> chance before the secret is in history.
>
> Note the hook redacts the value in its own output. Scanner logs are a leak channel too;
> CI systems archive them.

Clean up before the next exercise — `notes.txt` is still staged, and `git commit -a` in
exercise 8 would try to take it along:

```bash
$ git rm -q --cached notes.txt && rm -f notes.txt
$ cd ..
```

### Exercise 6 — Wire it into CI

Look at `exercises/.github-workflow-gitleaks.yml`. It's a drop-in GitHub Actions job that runs Gitleaks on every PR and fails the build on findings.

```yaml
- uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Copy it into a real repo's `.github/workflows/` to enable. (We can't run it in this lab
without a real GitHub repo, so this is the one exercise you cannot verify locally.)

The TruffleHog job in that file passes `--results=verified,unverified,unknown` rather than
the `verified,unknown` you will see in most copy-pasted examples — exercise 3 shows what
that difference costs you.

### Exercise 7 — What to do when you find a real secret

There's a runbook in `exercises/INCIDENT-RUNBOOK.md`. The order matters: **rotate first,
then clean up.** Many incidents are made worse by people frantically rewriting history
before they revoke the credential — the key stays live the whole time, and the force-push
destroys the timeline you would have used to work out what the attacker touched.

### Exercise 8 — Close the loop: remediate, then rescan

Simulate the real fix on `sample-repo`. "Rotating" a fake key means replacing it with a
reference to a secret store, which is what the code should have said in the first place:

```bash
$ cd sample-repo
# 1. ROTATE (pretend): in real life this happens first, in the provider console.
#    Everything below is step 3 of the runbook, not step 1.

# 2. Remove the values from the working tree
$ python3 - <<'EOF'
import json, pathlib
p = pathlib.Path("apps/web/config.json")
c = json.loads(p.read_text())
c["aws"] = {"accessKey": "${AWS_ACCESS_KEY_ID}", "secretKey": "${AWS_SECRET_ACCESS_KEY}", "region": "us-east-1"}
p.write_text(json.dumps(c, indent=2) + "\n")
EOF
$ sed -i.bak 's#https://hooks.slack.com/services/[^"]*#${SLACK_WEBHOOK_URL}#' apps/api/notify.js && rm apps/api/notify.js.bak
$ sed -i.bak 's/^GH_TOKEN=.*/GH_TOKEN=${GH_TOKEN}/' scripts/release.sh && rm scripts/release.sh.bak

#    ...and the one you planted yourself in exercise 4. Remediation covers everything the
#    scan found, including the finding you are least likely to think of as "real".
$ rm -f configs/internal.yaml

$ git commit -qam "chore: read credentials from the environment"
$ cd ..

# 3. Rescan the working tree -- should be clean
$ ./scripts/run-gitleaks.sh dir sample-repo --report-path exercises/after-tree.json --report-format json
```

> ✅ Expected: `no leaks found` for the **working tree**, and `exercises/after-tree.json`
> containing an empty array. If you skipped the `rm configs/internal.yaml` above you get one
> finding instead — worth doing once, on purpose, to see how easily a "clean" scan is one
> forgotten file away from a false all-clear.
>
> If you did exercise 5, the hook runs on that commit and passes: the diff only *removes*
> secrets. A pre-commit scanner looks at what you are adding, not at what the file used to
> say.

```bash
# 4. Now rescan the HISTORY
$ ./scripts/run-gitleaks.sh git sample-repo --report-path exercises/after-history.json --report-format json
$ jq 'length' exercises/after-history.json
```

> ✅ Expected: **still 7 findings across the same 4 commits** — byte for byte the exercise-2
> report, now with one more commit in the range that adds nothing to it. Your "fix" changed
> nothing about the exposure. This is
> the entire lesson of the lab in one command: the wall shrinks in the working tree and does
> not move in history, because history is what was published. Only rotation closes it.

Optional: run `git filter-repo --replace-text` (challenge 1) and rescan again to watch the
history findings finally disappear — and note that you had to force-push, break every
clone, and it *still* would not have helped if the repo had ever been public.

---

## 💡 Key Concepts

| Concept                       | TL;DR                                                                                              |
|-------------------------------|----------------------------------------------------------------------------------------------------|
| **Regex detection**           | Fast, easy to extend, lots of false positives. Most rules are regex.                               |
| **Entropy detection**         | Catches generic high-entropy strings (random base64-looking blobs). Slower, noisy without regex.   |
| **Verification**              | TruffleHog probes the actual API (e.g., AWS STS GetCallerIdentity) to confirm the key works.       |
| **`.gitleaksignore`**         | Per-finding allowlist by fingerprint. Use sparingly. Real secrets need rotation, not allowlisting. |
| **Rotation ≠ deletion**       | Pushed = compromised. Rotate the credential; deleting the file or rewriting history only tidies up afterwards. |
| **Canary patterns**           | Strings vendors publish (`AKIA...EXAMPLE`) that test scanners without granting access.             |
| **History rewriting**         | `git filter-repo` (recommended) or BFG. Coordinated; everyone re-clones afterward.                 |
| **Defense in depth**          | (1) IDE plugin → (2) pre-commit → (3) CI scan → (4) push protection (GitHub) → (5) post-commit alerting. |

### Detection strategy stack

```text
              FAST                           SLOW              EXPENSIVE
        ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
files → │   regex     │→ │   entropy    │→ │  validators  │→ │   live verify    │
        └─────────────┘  └──────────────┘  └──────────────┘  └──────────────────┘
        (Gitleaks)       (Gitleaks)        (TruffleHog)      (TruffleHog, on by default)
```

Use cheap layers everywhere. Use expensive layers in CI / nightly scans.

---

## 🏆 Challenge

1. **Purge a leaked secret from history.** Use [`git filter-repo`](https://github.com/newren/git-filter-repo) on `sample-repo` to remove `apps/web/config.json` from every commit. Verify with `gitleaks git sample-repo` that the secret is gone from history. Document your steps.
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
- [Gitleaks v8.19.0 release notes](https://github.com/gitleaks/gitleaks/releases/tag/v8.19.0) — where `git` / `dir` replaced `detect`

➡️ Next: [Lab 03 — SAST / Code Scanning](../03-sast-code-scanning/)
