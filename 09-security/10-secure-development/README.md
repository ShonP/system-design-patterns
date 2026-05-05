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
$ docker compose up -d
$ curl localhost:3001/api/health   # vulnerable
$ curl localhost:3002/api/health   # secure
```

You can hit both apps and compare their behavior side by side.

---

## 📝 Exercises

### Exercise 1 — Compare security headers

```bash
$ curl -sI localhost:3001/ | grep -iE 'content-security|x-frame|strict|x-content|permissions|cross-origin'
$ curl -sI localhost:3002/ | grep -iE 'content-security|x-frame|strict|x-content|permissions|cross-origin'
```

The vulnerable app sends none of these. The secure one sends a strict set.

The minimum set you should have:

| Header                                | Why                                                         |
|---------------------------------------|-------------------------------------------------------------|
| `Strict-Transport-Security`           | Force HTTPS for N seconds. Without it, downgrade is trivial.|
| `Content-Security-Policy`             | Whitelists what scripts/styles/images can load.             |
| `X-Content-Type-Options: nosniff`     | Prevent MIME sniffing.                                      |
| `X-Frame-Options: DENY` (or CSP frame-ancestors) | Anti-clickjacking.                              |
| `Referrer-Policy: strict-origin-when-cross-origin` | Don't leak full URLs to other origins.       |
| `Permissions-Policy`                  | Disable browser features (camera, mic, geolocation) you don't use.|

> 💡 The fix is one line in Express (`app.use(helmet())`) — these features are basically free.

### Exercise 2 — Trigger CORS the wrong way

```bash
$ curl -i -H 'Origin: https://evil.com' localhost:3001/api/me
# Vulnerable returns Access-Control-Allow-Origin: *  — credentialed requests now leak.
$ curl -i -H 'Origin: https://evil.com' localhost:3002/api/me
# Secure echoes only allowlisted origins, denies otherwise.
```

Read `secure-app/src/cors.ts`. Notice:

- An **explicit allowlist** of origins (no `*` when credentials are involved)
- `credentials: true` only when the origin matches
- A 403 when the origin is unknown — not a wide-open default

### Exercise 3 — Hit the rate limiter

```bash
$ for i in $(seq 1 20); do curl -s -o /dev/null -w "%{http_code}\n" localhost:3002/api/login -X POST -H 'content-type: application/json' -d '{"u":"a","p":"b"}'; done
```

> ✅ Expected: first ~5 requests `401`, then `429 Too Many Requests`. The vulnerable app keeps returning `401` forever — letting an attacker brute-force passwords at line speed.

### Exercise 4 — Input validation: schema vs hand-rolled

Look at `vulnerable-app/src/users.ts`:

```ts
app.post("/api/users", (req, res) => {
  const u = req.body;
  db.users[u.id] = u;        // VULN: prototype-pollution-friendly, type-unsafe, length-unsafe
  res.json(u);
});
```

vs `secure-app/src/users.ts`:

```ts
const Schema = z.object({
  id:     z.string().uuid(),
  email:  z.string().email().max(254),
  name:   z.string().min(1).max(100),
  role:   z.enum(["admin", "user"]),
}).strict();    // refuses unknown keys
```

Hit both:

```bash
$ curl -i -X POST localhost:3001/api/users -H 'content-type: application/json' \
    -d '{"id":"x","__proto__":{"polluted":true},"role":"admin"}'   # vulnerable: 200
$ curl -i -X POST localhost:3002/api/users -H 'content-type: application/json' \
    -d '{"id":"x","__proto__":{"polluted":true},"role":"admin"}'   # secure: 400 + validation errors
```

> 🧠 Validate at the boundary, not in your business logic. `zod` / `pydantic` / `joi` / `class-validator` all do this. Pick one per language and use it everywhere.

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

### Exercise 6 — Add a security `pre-commit` chain

```bash
$ cp exercises/.pre-commit-config.yaml secure-app/.pre-commit-config.yaml
$ cd secure-app && pre-commit install && pre-commit run --all-files
```

The bundle:

- gitleaks (secrets — lab 02)
- semgrep p/owasp-top-ten (SAST — lab 03)
- hadolint (Dockerfile lint — lab 04)
- checkov (IaC if any — lab 07)

This is the "every developer's laptop" layer. CI is the safety net behind it.

### Exercise 7 — Production-ready `Dockerfile`

Compare `vulnerable-app/Dockerfile` and `secure-app/Dockerfile`. The secure one:

- Multi-stage
- Non-root, fixed UID
- Read-only fs friendly
- `HEALTHCHECK`
- `--ignore-scripts` on `npm ci`
- Smaller base, no curl/build tools in final image

(All lessons from lab 04, applied.)

### Exercise 8 — End-to-end CI gate

Look at `exercises/ci/security.yml`. It's a single GitHub Actions workflow that runs:

```text
push → [trivy fs] [gitleaks] [semgrep] [checkov]
       └── all SARIF → GitHub code scanning UI
       └── any HIGH/CRITICAL net-new finding → block merge
```

Drop it into a real repo. Tune the `severity` and `exclude` lists for your codebase's noise floor.

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
| **Patch hygiene**             | Dependabot / Renovate. **Merge** the PRs, don't just open them.               |
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
- `research-report.md` §4.5 in this repo

---

## 🎓 Where to go next

You've finished the curriculum. Some natural next steps:

- **Build something.** Pick one lab and integrate its tooling into a real repo. The labs are the warm-up.
- **CTFs.** [HackTheBox](https://www.hackthebox.com/), [TryHackMe](https://tryhackme.com/), [PortSwigger Web Security Academy](https://portswigger.net/web-security).
- **Read incident reports.** Cloudflare, GitLab, AWS post-mortems are gold. Real-world distillations of every theme in these labs.
- **Contribute upstream.** Each tool here lives on GitHub. Issues, PRs, docs — there's always work.
- **Get a cert (if you must).** OSCP / OSWE / GPEN / CKS are the most respected. Treat them as "I sat in chair and proved I can do the thing," not as proof of skill.

Most of all: **rotate your laptop's habits.** `gitleaks` on every commit. `trivy` before every `docker push`. `nmap`-eye when reading network diagrams. The labs taught the moves; muscle memory is the rest.
