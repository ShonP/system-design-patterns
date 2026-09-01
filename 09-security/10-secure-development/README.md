# Lab 10 — Secure Development

## 🎯 What you'll learn

- Set up automated **dependency updates** with Dependabot and Renovate
- Apply the modern **HTTP security headers** (CSP, HSTS, COOP/COEP, Permissions-Policy)
- Configure **CORS** correctly — both as defender and as someone debugging another team's CORS
- Implement **rate limiting** (IP-based, user-based, per-endpoint)
- Validate input at trust boundaries with `zod` (Node) / `pydantic` (Python)
- Read every change in `vulnerable-app/` → `secure-app/` and understand why each line moved

## 📋 Prerequisites

- Docker + Node 20 (or run via the provided container)
- Lab 03 helpful (you'll see that the same patterns Semgrep flags are what we fix here)

## 🔧 Setup

```bash
$ cd 10-secure-development
$ docker compose up -d --build
$ curl localhost:3001/api/health   # vulnerable -> {"ok":true}
$ curl localhost:3002/api/health   # secure     -> {"ok":true}
```

You can hit both apps and compare their behavior side by side.

If 3001 or 3002 is already busy on your machine, move them — every script in
`scripts/` reads the same two variables:

```bash
$ export VULN_PORT=3011 SEC_PORT=3012
$ docker compose up -d --build
$ export VULN=http://localhost:$VULN_PORT SEC=http://localhost:$SEC_PORT
```

`ALLOWED_ORIGINS` on the secure app follows `SEC_PORT`, so the CORS exercise keeps
working on whatever port you picked.

---

## 📝 Exercises

### Exercise 1 — Compare security headers

```bash
# Side by side, both apps, the full header set (also flags a leaking X-Powered-By):
$ ./scripts/compare-headers.sh

# Or by hand, one app at a time:
$ curl -sI localhost:3001/ | grep -iE 'content-security|x-frame|strict|x-content|permissions|cross-origin'
$ curl -sI localhost:3002/ | grep -iE 'content-security|x-frame|strict|x-content|permissions|cross-origin'
```

`compare-headers.sh` honours `VULN` and `SEC` environment variables if you have
moved the apps off ports 3001/3002.

> ✅ Measured 2026-08-21 (helmet 8.3.0): the vulnerable column prints exactly one line —
> `X-Powered-By: Express`, the version-fingerprint you did not mean to publish. The secure
> column prints nine: CSP, HSTS, Referrer-Policy, X-Content-Type-Options, X-Frame-Options,
> the three `Cross-Origin-*` policies, and Permissions-Policy.

The minimum set you should have:

| Header                                | Why                                                         |
|---------------------------------------|-------------------------------------------------------------|
| `Strict-Transport-Security`           | Force HTTPS for N seconds. Without it, downgrade is trivial.|
| `Content-Security-Policy`             | Whitelists what scripts/styles/images can load.             |
| `X-Content-Type-Options: nosniff`     | Prevent MIME sniffing.                                      |
| `X-Frame-Options: DENY` (or CSP frame-ancestors) | Anti-clickjacking.                              |
| `Referrer-Policy: strict-origin-when-cross-origin` | Don't leak full URLs to other origins.       |
| `Permissions-Policy`                  | Disable browser features (camera, mic, geolocation) you don't use.|

Two things the diff will teach you that the table above will not:

- **helmet sends `X-Frame-Options: SAMEORIGIN`, not `DENY`.** Do not "fix" that. `X-Frame-Options`
  is the legacy header; the control that actually enforces here is CSP `frame-ancestors 'none'`,
  which the secure app sets and which no modern browser overrides. Grep for what enforces, not
  for the string you expected.
- **helmet does not set `Permissions-Policy` at all** — there is no default it could pick that
  would not break someone. `secure-app/src/index.js` sets it by hand, right above the CORS
  middleware. If you only ran `app.use(helmet())` and then grepped for `permissions-policy`,
  you would find nothing and conclude the header was there.

> 💡 The fix is nearly one line in Express (`app.use(helmet())`) — these features are basically
> free. "Nearly", because of the Permissions-Policy gap above: a middleware bundle is a floor,
> not a ceiling, and the way you find its edges is by curling the response, not by reading its
> README.

### Exercise 2 — Trigger CORS the wrong way

```bash
# Probe three origins at once -- an allowlisted one, an attacker one, and self.
# Watch the Access-Control-* and Vary headers change (or not) between them:
$ ./scripts/test-cors.sh http://localhost:3001/api/me   # vulnerable
$ ./scripts/test-cors.sh http://localhost:3002/api/me   # secure (the default)

# Or by hand:
$ curl -i -H 'Origin: https://evil.com' localhost:3001/api/me
$ curl -i -H 'Origin: https://evil.com' localhost:3002/api/me
```

> ✅ Measured 2026-08-21. Vulnerable, for all three origins: `200` with
> `Access-Control-Allow-Origin` **echoing whatever Origin you sent** —
> `https://evil.com` included — plus `Access-Control-Allow-Credentials: true` and no `Vary`.
> Secure: `200` for the two allowlisted origins with the origin echoed *and* `Vary: Origin`,
> `403 Forbidden` for `https://evil.com`.

Look closely at what makes the vulnerable version dangerous, because the obvious answer is
the wrong one:

- `Access-Control-Allow-Origin: *` on its own is careless but **not** a credential leak.
  A browser refuses to send cookies to a `*` response — `*` and `credentials: include` is a
  combination the fetch spec rejects outright. Plenty of "CORS is wide open!" findings are
  exactly this, and exactly this harmless.
- **Reflecting the Origin header is the bug that actually leaks.** `Access-Control-Allow-Origin:
  https://evil.com` + `Access-Control-Allow-Credentials: true` is a valid, browser-honoured
  pairing, so `evil.com` can make a cookie-bearing request to `/api/me` in a victim's browser
  and *read the response*. `vulnerable-app` does this in one line (`req.headers.origin || "*"`),
  which is also how it happens in real code: someone needed two origins to work, reflection
  "fixed" it, and the allowlist never got written.

Note the `Vary: Origin` header on the secure app: the response body now depends on a request
header, so without `Vary` a shared cache will happily serve the response it computed for one
origin to the next origin that asks.

Read the CORS middleware in `secure-app/src/index.js` (search for `allowedOrigins`). Notice:

- An **explicit allowlist** of origins (no `*` when credentials are involved)
- `credentials: true` only when the origin matches
- A 403 when the origin is unknown — not a wide-open default

### Exercise 3 — Hit the rate limiter

```bash
$ for i in $(seq 1 20); do curl -s -o /dev/null -w "%{http_code}\n" localhost:3002/api/login -X POST -H 'content-type: application/json' -d '{"u":"a","p":"b"}'; done
```

> ✅ Measured 2026-08-21: requests 1–5 return `401` (bad credentials), 6 onwards `429 Too Many
> Requests`, for a full 60-second window. The vulnerable app returns `401` for all 20 — and
> would for all 20 million, letting an attacker brute-force passwords at line speed.


Run it as a loop so you can watch the limiter engage, rather than mashing the
command by hand:

```bash
# 15 POSTs to the secure app's login endpoint; expect 401s (bad creds) then 429s
$ ./scripts/test-rate-limit.sh http://localhost:3002/api/login 15

# The same load against the vulnerable app never gets rate limited
$ ./scripts/test-rate-limit.sh http://localhost:3001/api/login 15
```

Now the part that makes the difference between a rate limit and the *appearance* of one:
**what is the counter keyed on, and can the caller change it?**

An IP-keyed limiter in an app that has `app.set("trust proxy", …)` switched on is not keyed
on the peer address at all — it is keyed on `X-Forwarded-For`, a request header. If nothing
in front of your app is actually overwriting that header, the attacker picks their own bucket. Watch it happen: bring
up a second copy of the secure app with proxy trust switched on, and rotate the header.

```bash
$ docker run -d --rm --name lab10-trustproxy -p 3013:3000 \
    -e TRUST_PROXY=1 -e ALLOWED_ORIGINS=https://app.example.com \
    10-secure-development-secure

# Same attacker, same account, a new "IP" every request:
$ for i in $(seq 1 8); do
    curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:3013/api/login \
      -H 'content-type: application/json' -H "X-Forwarded-For: 10.0.0.$i" \
      -d '{"u":"a","p":"b"}'
  done
```

> ✅ Measured 2026-08-21: `401 401 401 401 401 429 429 429`. The IP limiter is bypassed —
> every spoofed `X-Forwarded-For` gets its own fresh bucket — and the request is still
> stopped, by the **second** limiter in `secure-app`, the one keyed on the submitted
> username. Comment `authUserLimiter` out and rebuild, and the same loop returns eight `401`s.
>
> Then rotate the username too (`-d "{\"u\":\"user$i\",\"p\":\"b\"}"`) and you get
> `401` forever again. That is credential stuffing, and neither key catches it: one password
> against ten thousand accounts never trips a per-account counter. This is why a spike in
> 429s is a **signal to route somewhere**, not a problem you finished solving. The next layers
> are device/session fingerprinting, proof-of-work or CAPTCHA on anomalous logins, and
> breached-password rejection at registration.

```bash
$ docker rm -f lab10-trustproxy      # tidy up
```

Rules of thumb worth stealing:

- `trust proxy` is **off by default in `secure-app`** and switched on only by the `TRUST_PROXY`
  env var. Turn it on when — and only when — a proxy *you control* rewrites `X-Forwarded-For`,
  and set it to the exact number of hops. `app.set("trust proxy", true)` is the version that
  makes `req.ip` a free-text field.
- Limit on more than one key. Per-IP catches the loud single host; per-account catches the
  distributed guesser; the attacker who rotates both walks past each of them, which is what
  the layers after rate limiting are for.
- The limiter is only as trustworthy as the identity it counts. Anything the client can
  rewrite — a header, a cookie, a body field — is a bucket selector, not an identity.

### Exercise 4 — Input validation: schema vs hand-rolled

Look at the `/api/users` handler in `vulnerable-app/src/index.js`:

```js
app.post("/api/users", (req, res) => {
  const u = req.body;
  db.users[u.id] = _.merge({}, u);   // VULN: no schema + lodash 4.17.4 deep merge
  res.json(u);
});
```

vs the one in `secure-app/src/index.js`:

```js
const Schema = z.object({
  id:     z.string().uuid(),
  email:  z.string().email().max(254),
  name:   z.string().min(1).max(100),
  role:   z.enum(["admin", "user"]),
}).strict();    // refuses unknown keys
```

Hit both:

```bash
# Baseline: nothing has polluted Object.prototype yet
$ curl -s localhost:3001/api/canary          # {"polluted":false}

$ curl -s -X POST localhost:3001/api/users -H 'content-type: application/json' \
    -d '{"id":"x","__proto__":{"polluted":true},"role":"admin"}'   # vulnerable: 200

$ curl -s localhost:3001/api/canary          # {"polluted":true}  <-- every object in the process
$ curl -s -X POST localhost:3002/api/users -H 'content-type: application/json' \
    -d '{"id":"x","__proto__":{"polluted":true},"role":"admin"}'   # secure: 400 + issues[]
```

> ✅ The vulnerable app now returns `{"polluted":true}` **from an endpoint that never touched
> your request**. That is what prototype pollution means: you did not corrupt one record, you
> added a property to every object the process will ever create. Real escalations from here
> include forging `isAdmin` on objects that never had the key, poisoning library option
> objects, and RCE where a library reads config off a plain object.
>
> Two independent bugs had to line up: no schema at the boundary (so `__proto__` was accepted
> at all), and a deep merge from a lodash version predating the fix. `.strict()` in the
> secure app kills it at the first gate — the request is rejected before any library sees it.

Now the failure mode nobody demos, because it does not look like a failure:

```bash
$ curl -s -X POST localhost:3002/api/users -H 'content-type: application/json' \
    -d '{"id":"3f6c1a0e-2b7d-4c4a-9f1e-5d8b7a0c2e11","email":"mallory@evil.com",
         "name":"Mallory","role":"admin"}'
```

> ⚠️ Returns `201` with `"role":"admin"`. Every field is exactly what the schema asked for:
> a real UUID, a real email, a name within length, a role from the enum. `zod` did its whole
> job and the caller still just made themselves an administrator.
>
> **Validation answers "is this well-formed?", never "is this allowed?"** `role` passing
> `z.enum(["admin","user"])` says the string is one of two strings, not that *this* caller may
> set it. The authorization check is a separate line of code that this handler does not have —
> and the schema's green checkmark is what stops people from noticing it is missing. In a real
> service `role` would not be in the request schema at all: fields the client must not control
> get stripped from the input type and set server-side from the session.

While you are here, check the two boundaries either side of the schema:

```bash
$ python3 -c "print('{\"id\":\"x\",\"name\":\"' + 'a'*2000000 + '\"}')" > /tmp/big.json
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:3002/api/users \
    -H 'content-type: application/json' --data-binary @/tmp/big.json   # 413
$ curl -s -w "\n%{http_code}\n" -X POST localhost:3002/api/users \
    -H 'content-type: application/json' -d '{oops'                     # 400
```

> ✅ `413 {"error":"entity.too.large"}` and `400 {"error":"entity.parse.failed"}`. Both are
> refused by `express.json({ limit: "100kb" })` *before* `zod` sees anything — a 2 MB body
> never gets parsed, and a schema cannot protect you from work done to produce its input.
> Note also what the error handler in `secure-app` does with them: it forwards `err.status`
> instead of flattening every error to `500`. A body-size rejection reported as a server error
> is a client problem that pages you at 3am.

> 🧠 Validate at the boundary, not in your business logic. `zod` / `pydantic` / `joi` / `class-validator` all do this. Pick one per language and use it everywhere. And prefer `.strict()` / `extra="forbid"`: dropping unknown keys silently is better than merging them, rejecting them is what tells you someone is probing.

### Exercise 5 — Dependabot + Renovate configuration

`exercises/dependabot.yml` and `exercises/renovate.json` are drop-in configs.

**Dependabot** is GitHub-native, ships out of the box. Lower ceiling, higher floor:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule: { interval: "weekly" }
    open-pull-requests-limit: 10
    groups:
      patch-and-minor:
        update-types: ["minor", "patch"]
```

**Renovate** is more powerful (custom managers, lockfile maintenance, PR scheduling, grouping):

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended", ":semanticCommits"],
  "lockFileMaintenance": { "enabled": true, "schedule": ["before 5am on Monday"] },
  "vulnerabilityAlerts": { "labels": ["security"], "assignees": ["@security-team"] }
}
```

Pick one per repo (running both creates duplicate PRs). Either way: **schedule a recurring "merge the green ones" 30 minutes** every Monday.

**Neither tool can be exercised end-to-end here**, and it is worth being blunt about why:
Dependabot only runs on GitHub's own infrastructure against a repository it has been enabled
on, and Renovate needs an app installation or a self-hosted runner with a platform token.
There is no local mode that opens you a real PR. Do not enable either on a repository just to
watch it work.

What you *can* check locally is the thing that actually breaks in practice — the config file.
A typo in `.github/dependabot.yml` does not error; it silently disables the ecosystem, and you
find out months later that nothing has been updating.

```bash
# Dependabot: validate against the published schema (vendored, so it works offline)
$ uvx check-jsonschema --builtin-schema vendor.dependabot exercises/dependabot.yml

# Renovate: the validator ships in the renovate package itself
$ npx --yes --package renovate -- renovate-config-validator exercises/renovate.json
```

> ✅ Measured 2026-08-21 (check-jsonschema 0.38.0, renovate 37.440.7 as resolved by npx):
> `ok -- validation done` and ` INFO: Config validated successfully`, both exit `0`.

Now prove the checks bite, which is the only way to know a green result meant anything:

```bash
$ cat > /tmp/bad-dependabot.yml <<'EOF'
version: 2
updates:
  - package-ecosystem: "nodejs"          # it is "npm"
    directory: "/"
    schedule: { interval: "fortnightly" }  # not a real interval
EOF
$ uvx check-jsonschema --builtin-schema vendor.dependabot /tmp/bad-dependabot.yml; echo "exit=$?"

$ cat > /tmp/bad-renovate.json <<'EOF'
{ "extends": ["config:recommended"],
  "schedule": ["every Monday at 5am"],
  "packageRules": [{ "matchUpdateTypes": ["minor"], "automerge": "yes" }] }
EOF
$ npx --yes --package renovate -- renovate-config-validator /tmp/bad-renovate.json; echo "exit=$?"
```

> ✅ Both exit `1`. check-jsonschema names the two bad enum values and the JSON path to each;
> the Renovate validator reports `automerge` should be boolean, found `"yes"` (string), and
> `Failed to parse "every Monday at 5am"` — Renovate's schedule syntax is
> [later.js](https://breejs.github.io/later/parsers.html) text, and it is stricter than it
> looks. Wire both commands into CI so a broken bot config fails a PR instead of quietly
> switching your updates off.

### Exercise 6 — Add a security `pre-commit` chain

`pre-commit` is repository-scoped, not directory-scoped: run it from inside `secure-app/`
and it will still walk up, find *this* repo's `.git`, install hooks for the whole
`system-design-patterns` tree and scan every lab in it. To try the chain on one app only,
copy the app somewhere and give it its own repo:

```bash
$ cp -R secure-app /tmp/pcdemo && cp exercises/.pre-commit-config.yaml /tmp/pcdemo/
$ cd /tmp/pcdemo && git init -q . && git add -A && git -c user.email=you@example.com \
    -c user.name=you commit -qm init
$ pre-commit run --all-files
```

The bundle:

- gitleaks (secrets — lab 02)
- semgrep p/owasp-top-ten (SAST — lab 03)
- hadolint (Dockerfile lint — lab 04)
- checkov (IaC if any — lab 07)

> ✅ Measured 2026-08-21 (pre-commit 4.x, Python 3.14, on `secure-app`):
> ```text
> Detect hardcoded secrets.................................................Passed
> semgrep..................................................................Passed
> Lint Dockerfiles.........................................................Passed
> Checkov..............................................(no files to check)Skipped
> ```
> Run the same chain against `vulnerable-app` and semgrep returns **2 blocking findings** —
> `dockerfile.security.missing-user` (no `USER`, so the container runs as root) and
> `javascript.express.security.cors-misconfiguration` on the reflected Origin from exercise 2.
> That difference is the exercise. A chain that prints the same thing for both apps is a
> chain you have not tested.

Read `exercises/.pre-commit-config.yaml` before you copy it — three of the four hooks are not
the id you would have guessed, and the comments say why:

- **`hadolint-docker`, not `hadolint`.** The plain `hadolint` id is a `language: system` hook:
  it runs whatever `hadolint` is already on your `PATH` and fails with "executable not found"
  if there isn't one. `-docker` is self-contained.
- **`checkov_container`, not `checkov`.** The Python hook builds checkov from source into a
  fresh virtualenv; on Python 3.13+ that pulls `rustworkx<0.14`, which has no wheel and needs
  a Rust toolchain, and pre-commit aborts the *entire run* on the install failure — no hook
  gets to execute, including the three that would have worked. Both checkov ids only match
  `*.tf`, so in a repo with no Terraform they report `(no files to check) Skipped`; it earns
  its keep in the lab 07 repo, and it is here so you see the shape of a full chain.
- **semgrep is pinned to a current rev, and that pin is load-bearing.** The natural-looking
  `rev: v1.96.0` cannot start on Python 3.13+ at all: its pinned protobuf dies with
  `TypeError: Metaclasses with custom tp_new are not supported` before semgrep parses a single
  file. A pre-commit `rev` is a *tool* version, not a rule version — stale ones rot against
  your interpreter, and the failure is a stack trace, not a finding.
- **gitleaks' hook scans the staged diff only** (`gitleaks git --pre-commit --staged`). Under
  `--all-files` nothing is staged, so `Passed` means "scanned nothing". It is the right
  behaviour for a commit hook and a trap in a demo — for a real sweep use lab 02's
  `gitleaks git .` against history.

Note the four-line comment above the CORS `setHeader` in `secure-app/src/index.js`. Semgrep
flags that echo, and it is a false positive — the origin is allowlist-checked immediately
above — so it carries a `// nosemgrep:` with the rule name and the reason, at the site.
That is the whole discipline: suppress one finding where a reviewer will read the reason,
never disable the rule repo-wide.

This is the "every developer's laptop" layer. CI is the safety net behind it — a pre-commit
hook is advisory (`--no-verify` removes it) and a required CI check is not.

### Exercise 7 — Production-ready `Dockerfile`

Compare `vulnerable-app/Dockerfile` and `secure-app/Dockerfile`. The secure one:

- Multi-stage
- Non-root, fixed UID
- Read-only fs friendly
- `HEALTHCHECK`
- `--ignore-scripts` on `npm ci`
- Smaller base, no curl/build tools in final image

Then measure instead of admiring:

```bash
$ docker run --rm -i ghcr.io/hadolint/hadolint hadolint - < vulnerable-app/Dockerfile
$ docker run --rm -i ghcr.io/hadolint/hadolint hadolint - < secure-app/Dockerfile
```

> ✅ Measured 2026-08-21 (hadolint 2.12.x): **both exit `0`, clean.** That is not the result
> you were expecting, and it is the point of running it. hadolint is a *style and syntax*
> linter — it will tell you a base image is untagged or a `RUN` is unpinned, and it has no
> opinion whatsoever about the vulnerable Dockerfile's actual problems: root user, full
> `node:20` base with a compiler in it, no `--ignore-scripts`, no healthcheck. Semgrep's
> `dockerfile.security.missing-user` (exercise 6) catches the root one; a scanner from lab 04
> catches the base image. One clean linter is one clean linter.
>
> The two findings that *did* exist here were on the hardened file, not the vulnerable one:
> `DL3066` (`USER app` — a name the host cannot resolve to a uid; it is now `USER 10001:10001`)
> and `DL3025` (a shell-form `HEALTHCHECK CMD`; now exec-form `wget --spider`). Hardening a
> Dockerfile adds directives, and every directive you add is new surface for a linter to
> disagree with.

(All lessons from lab 04, applied.)

### Exercise 8 — End-to-end CI gate

Look at `exercises/ci/security.yml`. It's a single GitHub Actions workflow that runs:

```text
push → [trivy fs] [gitleaks] [semgrep] [checkov]
       └── all SARIF → GitHub code scanning UI
       └── any HIGH/CRITICAL net-new finding → block merge
```

**This one only runs on GitHub.** SARIF upload needs `security-events: write` against a real
repository, and `gitleaks-action` wants a `GITHUB_TOKEN`. There is no way to complete it from
this lab, so do not go looking for one — drop it into a repo you already own when you have one.

What you can do locally is catch the class of mistake that costs the most time: a workflow
that is syntactically fine and semantically wrong (a misspelled `runs-on`, a `with:` key the
action does not take, a shell-injectable `${{ }}` interpolation), which you would otherwise
discover one push at a time.

```bash
$ mkdir -p /tmp/wf/.github/workflows && cp exercises/ci/security.yml /tmp/wf/.github/workflows/
$ cd /tmp/wf && git init -q .          # actionlint needs a repo root to anchor on
$ docker run --rm -v /tmp/wf:/repo --workdir /repo rhysd/actionlint:latest -color
$ echo "exit=$?"
```

> ✅ Measured 2026-08-21: no output, exit `0` — the workflow is clean. Add a typo
> (`runs-on: ubunut-latest`) and re-run to see it named with a line and column.

Tune the `severity` and `exclude` lists for your codebase's noise floor. And note what the
diagram claims versus what the file does: uploading SARIF makes findings *visible* in the code
scanning UI; **blocking a merge on them is a branch protection rule**, configured on the
repository, not in this YAML. A workflow that reports and a workflow that gates look identical
in the file.

### Exercise 9 — Dependencies: pinned is not patched

`vulnerable-app/package.json` pins every dependency to an **exact** version. That is what
people mean when they say a build is "locked down". Now look at what is installed:

```bash
$ docker compose exec vulnerable npm ls --depth=0
$ docker compose exec vulnerable npm audit
```

> ✅ Measured 2026-08-21: `10 vulnerabilities (3 low, 5 high, 2 critical)` across ten packages
> — critical prototype pollution in `lodash@4.17.4` (the bug you just exploited) and
> `minimist@1.2.0`, high SSRF + CSRF in `axios@0.21.0`, and six more that arrived through
> `express@4.17.1`'s own dependencies (`path-to-regexp`, `qs`, `send`, `serve-static`,
> `body-parser`, `cookie`) — none of which appear in `package.json`. Expect the exact count to
> drift as advisories are filed; expect the shape (a handful of directs, more transitives,
> at least one critical) to hold.

Then run the same command against the other app:

```bash
$ docker compose exec secure npm audit
```

> ✅ `found 0 vulnerabilities`. Same registry, same day, same feed. The only difference is that
> `secure-app/package.json` uses caret ranges (`^4.21.0`) and was built recently, so `npm ci`
> resolved current patches — while `vulnerable-app` pins exact versions and gets exactly what
> it asked for, forever. Neither file is "more locked down" than the other; one of them is
> just older.

> ⚠️ **Pinning is a reproducibility control, not a security control.** An exact version and a
> committed lock file guarantee everyone builds the same artifact. They say nothing about
> whether that artifact is safe, and by design they *stop* you from picking up the fix. A
> pinned dependency stays vulnerable until a human moves it. What you need is: pin **and** an
> automated bump (Dependabot/Renovate) **and** someone who merges the PRs. Two out of three
> is where most repos are, and it is the combination that looks safest on a dashboard.

Now run the loop:

```bash
# 1. Bump the offenders in vulnerable-app/package.json. Do NOT copy these numbers on
#    faith -- run `npm audit` and take the "Will install X" line it prints for each.
#    Clean as measured on 2026-08-21:
#      lodash    4.17.4  -> 4.18.1
#      minimist  1.2.0   -> 1.2.8
#      axios     0.21.0  -> 1.19.0    (major bump: read the changelog, not just the CVE)
#      express   4.17.1  -> 4.22.2
# 2. Rebuild and re-audit
$ docker compose build vulnerable && docker compose up -d --build vulnerable
$ docker compose exec vulnerable npm audit

# 3. Re-verify the BEHAVIOUR, not just the advisory count
$ curl -s localhost:3001/api/canary
$ curl -s -X POST localhost:3001/api/users -H 'content-type: application/json' \
    -d '{"id":"x","__proto__":{"polluted":true},"role":"admin"}' >/dev/null
$ curl -s localhost:3001/api/canary
```

> ✅ Measured 2026-08-21 with the versions above: `found 0 vulnerabilities`, and the canary
> stays `false` — the patched lodash refuses to merge `__proto__`. **Notice which of those two
> facts matters.** The advisory count is a report; the canary is the behaviour. There are many
> ways to make the first happen without the second (`npm audit --omit=dev`, an `audit-ci`
> allowlist, an override that pins a transitive package the code never reaches).
>
> ⏳ And a live demonstration of the lab's own thesis: the version list this exercise shipped
> with — `lodash 4.17.21`, `express 4.21.2`, `axios 1.7.7` — was clean when it was written and
> scores **6 vulnerabilities (2 moderate, 4 high)** today, because advisories widened to cover
> those releases (`lodash <=4.17.23`, `path-to-regexp <0.1.13` and `qs <=6.15.1` inside
> express, and axios' own later CVEs). A "we patched it" note in a README has a shelf life
> measured in months. If the numbers above no longer reproduce for you, that is the exercise
> working, not the exercise broken — re-derive them and notice how little time it took.
>
> And the endpoint is still unvalidated — the next deep-merge CVE brings the bug straight
> back. Upgrading removed *this instance*; `.strict()` in `secure-app` removed the *class*.

### Exercise 10 — Close the loop on the app itself

Port the secure app's controls into `vulnerable-app/src/index.js` yourself, one at a time,
re-running the check after each so you can see which control closed which finding:

| # | Change | Verify with |
|---|---|---|
| 1 | `app.disable("x-powered-by")` | `./scripts/compare-headers.sh` |
| 2 | `app.use(helmet({...}))` | `./scripts/compare-headers.sh` |
| 3 | Replace the reflected `req.headers.origin` with an allowlist + `Vary: Origin` | `./scripts/test-cors.sh http://localhost:3001/api/me` |
| 4 | `express-rate-limit` on `/api/login` | `./scripts/test-rate-limit.sh http://localhost:3001/api/login 15` |
| 5 | `zod` schema with `.strict()` on `/api/users` | the canary calls from exercise 9 |
| 6 | `express.json({ limit: "100kb" })` + an error handler that forwards `err.status` | POST a 2 MB body → `413`, not `500` |

```bash
$ docker compose build vulnerable && docker compose up -d --build vulnerable
$ ./scripts/compare-headers.sh          # both columns should now look the same
```

> ✅ Done when `compare-headers.sh` prints the same header set for both apps,
> `test-cors.sh` rejects `https://evil.com` on both, and `test-rate-limit.sh` produces 429s
> on both. At that point you have written `secure-app` yourself, which is the only version
> of this that sticks.
>
> Row 6 is the one people skip, and it is the one that catches the habit: adding
> `express.json({ limit: "100kb" })` is not enough on its own. A catch-all error handler that
> answers every error with `500` turns the 413 back into a server error — the control fires
> and the response lies about it. Check the status code, not the middleware list.

---

## 💡 Key Concepts

| Concept                       | TL;DR                                                                         |
|-------------------------------|-------------------------------------------------------------------------------|
| **Defense in depth**          | Many cheap layers > one expensive layer. Every lab adds one.                  |
| **Validate at the boundary**  | `zod` / `pydantic` / `joi` at the controller. Your business logic trusts data.|
| **Allowlist > denylist**      | For CORS, file types, redirects, hostnames, … always allowlist.               |
| **Fail closed**               | If config is missing or auth check errors out, the answer is `403`, not `200`.|
| **Zero-trust** in code        | Don't trust the previous layer. Validate again. Log auth decisions.           |
| **Least privilege**           | Containers run as non-root, IAM has minimal `*` resources, k8s RBAC is scoped.|
| **Patch hygiene**             | Dependabot / Renovate. **Merge** the PRs, don't just open them — an open PR queue is the same exposure window with extra steps. |
| **Pinned ≠ patched**          | Exact versions and lock files buy reproducibility, and freeze your vulnerabilities in place. Pin *and* automate the bump. |
| **Update strategy**           | Automerge patch/minor on green CI; batch and schedule majors; take `vulnerabilityAlerts` PRs out-of-band immediately. Budget review time — unreviewed automerge is its own supply-chain surface (`event-stream`, `ua-parser-js`, `xz`). |
| **Transitive depth**          | Most of your tree is not in `package.json`. `npm ls --all` and an SBOM (lab 01) are how you see it; `overrides`/`resolutions` are how you patch it when the direct dependency has not moved. |
| **Secrets management**        | Env vars from a secret store, never hardcoded. (Lab 02 covers detection.)     |

### The mental model: trust boundaries

```text
                Internet
                   │
            ┌──────▼───────┐    ← TLS, WAF, rate-limit
            │  Edge / LB   │
            └──────┬───────┘
                   │  trust = none
            ┌──────▼───────┐    ← AuthN, AuthZ, validate
            │   Service    │
            └──────┬───────┘
                   │  trust = authenticated user
            ┌──────▼───────┐    ← Parameterized queries, allowlists
            │   Database   │
            └──────────────┘
```

Every arrow is a boundary. Validate at every boundary.

---

## 🏆 Challenge

1. **Strict CSP rollout.** Take `secure-app` from a permissive `default-src 'self'` to a fully-locked-down policy with **nonces** for every inline `<script>`. Demonstrate the staged rollout: report-only → enforcing.
2. **Per-user rate limit.** Beyond IP, rate-limit by user ID for authenticated endpoints. Use Redis. Demonstrate that the same user from two IPs still gets limited.
3. **Auth + session hardening.** Replace the demo-grade auth in `secure-app` with a proper auth flow: argon2 password hash, JWT with `kid` rotation, refresh tokens, idle/absolute session timeouts.
4. **End-to-end run of all 10 labs.** Wire `secure-app` to use lab 06 manifests, lab 07 Terraform, lab 04 Dockerfile, lab 02 pre-commit, lab 03 SAST in CI, lab 01 SBOM in releases. Show that a single PR runs the whole stack.

---

## 📚 Further reading

- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) — what "secure" means, in checklist form
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) — pragmatic, language-specific
- [Dependabot docs](https://docs.github.com/en/code-security/dependabot)
- [Renovate docs](https://docs.renovatebot.com/)
- [Helmet.js](https://helmetjs.github.io/) — what Express security headers should look like
- [zod](https://zod.dev/) / [Pydantic](https://docs.pydantic.dev/)
- [12 Factor App: Config](https://12factor.net/config) — never `ENV API_KEY=...`
- [CVE-2018-3721 — lodash prototype pollution](https://github.com/advisories/GHSA-fvqr-27wr-82fm) — the bug in exercise 4

---

## 🎓 Where to go next

You've finished the curriculum. Some natural next steps:

- **Build something.** Pick one lab and integrate its tooling into a real repo. The labs are the warm-up.
- **CTFs.** [HackTheBox](https://www.hackthebox.com/), [TryHackMe](https://tryhackme.com/), [PortSwigger Web Security Academy](https://portswigger.net/web-security).
- **Read incident reports.** Cloudflare, GitLab, AWS post-mortems are gold. Real-world distillations of every theme in these labs.
- **Contribute upstream.** Each tool here lives on GitHub. Issues, PRs, docs — there's always work.
- **Get a cert (if you must).** OSCP / OSWE / GPEN / CKS are the most respected. Treat them as "I sat in chair and proved I can do the thing," not as proof of skill.

Most of all: **rotate your laptop's habits.** `gitleaks` on every commit. `trivy` before every `docker push`. `nmap`-eye when reading network diagrams. The labs taught the moves; muscle memory is the rest.
