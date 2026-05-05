# Lab 05 — Web App Security with OWASP Juice Shop & ZAP

## 🎯 What you'll learn

- Run **OWASP Juice Shop**, the most-deployed deliberately-vulnerable web app, locally
- Use **OWASP ZAP** as both an automated **DAST** scanner (baseline + full) and an interactive **proxy**
- Find and exploit (in the lab!) the **OWASP Top 10**: injection, XSS, broken access control, broken auth, SSRF, etc.
- Use **Nuclei** for fast template-based vulnerability checks
- Read DAST output and translate it into developer-actionable fixes
- Understand the limits of DAST vs SAST (lab 03)

> ⚠️ Run everything in this lab on `localhost`. Don't point ZAP at sites you don't own.

## 📋 Prerequisites

- Docker + ~2 GB free disk
- A modern browser
- Lab 03 helpful but not required

## 🔧 Setup

```bash
$ cd 05-web-app-security-owasp
$ docker compose up -d juice-shop
$ open http://localhost:3000     # macOS — or just visit it in a browser
```

Click around the Juice Shop — order a juice, leave a review. Get a feel for the app first; you scan apps better when you know how they're meant to work.

When done with the lab:

```bash
$ docker compose down -v
```

---

## 📝 Exercises

### Exercise 1 — Solve a few challenges by hand

Juice Shop tracks 100+ challenges across difficulty tiers. Open the **score board** by guessing its URL (this is challenge #0 — a hint: it's not in any link, but the app is built with Angular and there's a `routes` file in the JS bundles…).

Try these by hand:

| Challenge                | Hint                                                |
|--------------------------|-----------------------------------------------------|
| Login Admin              | Boolean-based SQLi in the login form (`' OR 1=1--`) |
| DOM XSS                  | The search box reflects HTML.                       |
| Confidential Document    | An admin endpoint isn't checking auth properly.     |
| Forged Feedback          | The feedback form has client-side-only validation.  |

> 💡 Goal: feel **how an attacker thinks** — try all the obvious things first.

### Exercise 2 — ZAP Baseline scan (passive)

The fastest, safest DAST scan. Spider the site, observe traffic, report on missing headers / cookies / TLS / common misconfigs. **No active exploit attempts.**

```bash
$ ./scripts/zap-baseline.sh
# writes: exercises/zap-baseline.html  exercises/zap-baseline.json
```

Open the HTML report. You should see findings like:

- `Missing Anti-clickjacking Header`
- `X-Content-Type-Options` not set
- `Content Security Policy` not set
- Cookies without `Secure`/`HttpOnly`/`SameSite`

> ✅ These are "free" findings — every prod site should have zero of them. Lab 10 covers the fix layer.

### Exercise 3 — ZAP Full scan (active)

The full scan injects payloads and tries to confirm vulnerabilities. **Slow** (10–30 min). Run it once to see what it finds, then move on.

```bash
$ ./scripts/zap-full.sh
# writes: exercises/zap-full.html  exercises/zap-full.json
```

Compare against baseline — full scan adds **active** findings: SQLi, XSS, path traversal, CSRF, etc.

### Exercise 4 — Use ZAP as a proxy

The most useful mode for actual app testing.

```bash
$ ./scripts/zap-proxy.sh    # starts ZAP daemon on :8080 + WebUI on :8090
```

Configure your browser to use `localhost:8080` as HTTP+HTTPS proxy (for Juice Shop only, not your whole laptop), trust ZAP's CA cert (printed by the script), then browse the app while ZAP records traffic.

Now you can:

- right-click any request → **Attack → Active scan** (target this single endpoint)
- right-click a parameter → **Fuzz** (try a custom payload list)
- replay requests with modifications via **Manual Request Editor**

This is the core DAST workflow.

### Exercise 5 — Nuclei: fast templated scans

```bash
$ ./scripts/run-nuclei.sh -u http://localhost:3000 -severity medium,high,critical
$ ./scripts/run-nuclei.sh -u http://localhost:3000 -t http/exposures
$ ./scripts/run-nuclei.sh -u http://localhost:3000 -t http/cves -severity high,critical
```

Nuclei is template-based — every check is a YAML file. Browse [`projectdiscovery/nuclei-templates`](https://github.com/projectdiscovery/nuclei-templates) to see the catalog.

> 💡 **DAST vs Nuclei.** ZAP is exploratory and great at finding logic bugs by behaving like a browser. Nuclei is specific — "is this CVE present at this URL." You want both in CI.

### Exercise 6 — SQL injection deep-dive

Use ZAP proxy + the login endpoint. Submit `admin@juice-sh.op' --` as the email, anything as password. Watch the request in ZAP, see how the backend returns success.

Now look at the code in [`bkimminich/juice-shop`](https://github.com/juice-shop/juice-shop) — `routes/login.ts` literally interpolates the email into a SQL string. The fix is parameterized queries (`$1`, `$2`).

> 🔁 **Tie it back to lab 03.** Semgrep should flag this exact pattern. Run lab 03's `no-sql-concat` rule against the Juice Shop source if you cloned it — it catches the same bug statically.

### Exercise 7 — XSS payload variations

The reviews / feedback fields are vulnerable. Try (in the lab only):

```html
<img src=x onerror="alert('xss')">
<svg/onload="alert('xss')">
<iframe srcdoc="<script>alert('xss')</script>">
```

Now re-run ZAP active scan against `/api/Feedbacks` — it should auto-confirm the XSS without you supplying payloads.

### Exercise 8 — Fix one vulnerability end-to-end

Pick **DOM XSS in the search box**:

1. Reproduce in ZAP and the browser
2. Read the offending Angular template (`/frontend/src/app/search-result/search-result.component.html`)
3. Note the `[innerHTML]` binding without sanitization
4. The fix: switch to `[textContent]` (or use Angular's `DomSanitizer.sanitize(...)`)
5. Re-run ZAP active scan against `/#/search?q=...` — finding gone

You don't have to push the fix; the point is to walk the loop **find → understand → fix → verify**.

---

## 💡 Key Concepts

| Concept              | TL;DR                                                                              |
|----------------------|------------------------------------------------------------------------------------|
| **DAST**             | Dynamic Application Security Testing — black-box scanning of a running app.        |
| **Spider / crawl**   | Walk every link to enumerate endpoints. ZAP has both classic and AJAX spiders.     |
| **Active vs passive**| Passive observes; active sends payloads. Active can break things — never on prod.  |
| **Authenticated scan**| You need to teach ZAP how to log in. Otherwise it only sees public pages.         |
| **CSP**              | Content-Security-Policy — defense-in-depth header that mitigates most XSS.         |
| **CWE-79 / CWE-89**  | XSS / SQLi — the two single biggest categories of web vulns.                        |
| **OWASP Top 10**     | The everyone-agrees list. Memorize 2021's: A01–A10.                                |

### OWASP Top 10 2021 (memorize)

1. **A01 — Broken Access Control**
2. **A02 — Cryptographic Failures**
3. **A03 — Injection** (SQL, command, LDAP, NoSQL, …)
4. **A04 — Insecure Design**
5. **A05 — Security Misconfiguration**
6. **A06 — Vulnerable & Outdated Components**
7. **A07 — Identification & Authentication Failures**
8. **A08 — Software & Data Integrity Failures**
9. **A09 — Security Logging & Monitoring Failures**
10. **A10 — Server-Side Request Forgery (SSRF)**

Juice Shop has at least one challenge per category — you can build a personal Top-10 portfolio just by solving them.

### Where DAST fits vs SAST

```text
SAST (lab 03):  reads source           → finds bugs in YOUR code
SCA  (lab 01):  reads dependencies     → finds bugs in OTHER code
DAST (this lab): reads HTTP responses  → finds bugs the runtime exhibits
                                          (incl. config, headers, deploy issues)
```

You need all three. DAST especially catches **deployment** issues — wrong CSP, missing rate limit, debug endpoint enabled — which SAST can't.

---

## 🏆 Challenge

1. **Authenticated full scan.** Configure ZAP to log in as a Juice Shop user (using a context + auth script), then run the full scan. Compare findings vs unauthenticated.
2. **Solve 25 challenges.** Pick 25 score-board challenges and document your steps. This is one of the better "portfolio" exercises.
3. **CI integration.** Write a GitHub Actions workflow that boots Juice Shop, runs `zap-baseline`, and posts findings as PR comments. Bonus: fail only on net-new findings vs the `main` branch.
4. **Custom Nuclei template.** Write a Nuclei template that detects the Juice Shop "Confidential Document" challenge (an unauthenticated FTP endpoint exposes `package.json.bak`). Submit a PR upstream if it's novel.

---

## 📚 Further reading

- [OWASP Juice Shop](https://github.com/juice-shop/juice-shop) — the source code is the answer key
- [Pwning OWASP Juice Shop](https://pwning.owasp-juice.shop/) — official walkthrough book
- [OWASP ZAP docs](https://www.zaproxy.org/docs/)
- [Nuclei templates](https://github.com/projectdiscovery/nuclei-templates)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [Web Security Academy (PortSwigger)](https://portswigger.net/web-security) — best free training on the planet
- `research-report.md` §4.3 in this repo

➡️ Next: [Lab 06 — Kubernetes Security](../06-kubernetes-security/)
