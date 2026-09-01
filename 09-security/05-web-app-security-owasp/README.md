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

> ⚠️ **Port 3000 is the most contended port on a developer laptop** (every Node tutorial
> ever written uses it, and labs 01/04/10 build apps that also default to it). If the
> container fails to bind:
>
> ```bash
> $ JUICE_PORT=3010 docker compose up -d juice-shop
> $ TARGET=http://host.docker.internal:3010 ./scripts/zap-baseline.sh
> ```
>
> Every scan script reads `TARGET`; keep the two in sync.

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

Open the HTML report. The passive scan reports a handful of missing-header and
misconfiguration findings. Measured on 2026-08-21 against `bkimminich/juice-shop:v17.3.0`
with `ghcr.io/zaproxy/zaproxy:stable` (ZAP 2.17.0) — **13 alerts**, the notable ones being:

- `Content Security Policy (CSP) Header Not Set` (Medium) — the big one Exercise 9 closes
- `Cross-Domain Misconfiguration` (Medium) — Juice Shop answers `Access-Control-Allow-Origin: *`
- `Vulnerable JS Library` (High) — an outdated bundled library
- `Cross-Origin-Embedder-Policy` / `Cross-Origin-Opener-Policy Header Missing` (Low)
- `Deprecated Feature Policy Header Set` (Low) — the app still sends `Feature-Policy`

> ⚠️ **What you will *not* see, and why it matters.** Older walkthroughs of this exercise
> expect `Missing Anti-clickjacking Header`, `X-Content-Type-Options` not set, and insecure
> cookies. This Juice Shop build already sends `X-Frame-Options: SAMEORIGIN` and
> `X-Content-Type-Options: nosniff` (verify: `curl -sI localhost:3000`), so ZAP does not
> flag them, and the pages the spider reaches set no cookies, so there is no cookie finding.
> The lesson is real: **a scanner reports what the current build actually does** — pin the
> app version and re-measure rather than trusting a number from a blog post.

> ✅ These header findings are "free" — cheap to close and worth closing. Exercise 9 fixes
> the CSP/COOP class here at the edge, and lab 10 shows the in-app version (`helmet()`).

**Read a baseline report the right way.** A passive finding is a statement about the
*response*, not about an exploit: "there is no `X-Frame-Options` header" is a fact; "this
site is clickjackable" is a conclusion that also depends on whether any page has an action
worth framing. Baseline scans are cheap enough to run on every deploy precisely because
they make no claims they cannot back up — and correspondingly, a clean baseline says
almost nothing about whether the app is secure.

### Exercise 3 — ZAP Full scan (active)

The full scan injects payloads and tries to confirm vulnerabilities. **Slow** (10–30 min). Run it once to see what it finds, then move on.

```bash
$ ./scripts/zap-full.sh
# writes: exercises/zap-full.html  exercises/zap-full.json
```

Compare against baseline — the full (active) scan adds findings the passive scan cannot make:

```bash
$ jq -r '.site[].alerts[] | "\(.riskdesc)\t\(.alert)"' exercises/zap-baseline.json | sort -u
$ jq -r '.site[].alerts[] | "\(.riskdesc)\t\(.alert)"' exercises/zap-full.json     | sort -u
```

Measured on 2026-08-21 (`juice-shop:v17.3.0`, ZAP 2.17.0): baseline **13** alerts, full
**17**. The five the active scan adds are:

- `Backup File Disclosure` (Medium) — it found the `.bak` files under `/ftp` (Confidential Document)
- `CORS Misconfiguration` (Medium)
- `Bypassing 403` (Medium)
- `HTTP Only Site` (Medium) — the app is served over plain HTTP
- `User Agent Fuzzer` (Info)

> ⚠️ **Notice what is *not* there: no SQL injection, no XSS.** The classic claim that a full
> scan "adds SQLi and XSS" does **not** hold for Juice Shop scanned this way, and that is the
> single most important thing this exercise teaches. Juice Shop is an Angular **single-page
> app**: its real attack surface is the JSON API (`/rest/*`, `/api/*`), and ZAP's traditional
> spider — which follows links in HTML — never discovers it. Confirm it yourself:
> `jq -r '.site[].alerts[].instances[]?.uri' exercises/zap-full.json | grep -E '/rest/|/api/'`
> returns nothing. The scanner attacked the static shell, not the app. To make an active scan
> reach these bugs you need the **AJAX spider**, an imported API definition, or an
> **authenticated context** (see the Challenge section) — which is exactly why the SQLi and XSS
> in Exercises 1, 6, 7 and 8 are found *by hand*, not by pointing a scanner at the front door.

**This is still the difference that matters between DAST and everything else in this repo.** A
Trivy finding says a vulnerable package is present. A Semgrep finding says a dangerous
pattern is in the source. A ZAP *active* finding says: I sent this payload to this URL, and
the response proves it worked. That is evidence of exploitability, not of the presence of a
weakness — which is why a single confirmed active finding outranks a page of CVEs, and why
active scans are also the ones that can corrupt data and must never touch production. The
flip side, above, is just as important: **an active scan only tests the surface it can find**,
and a clean full scan of a SPA usually means the scanner never reached the app.

### Exercise 4 — Use ZAP as a proxy

The most useful mode for actual app testing.

```bash
$ ./scripts/zap-proxy.sh    # ZAP daemon: proxy + REST API on :8080. No GUI.
```

Configure your browser to use `localhost:8080` as its HTTP+HTTPS proxy (a separate Firefox
profile — not your whole laptop), then visit `http://zap/` **through that proxy** to
download and trust ZAP's CA certificate. Now browse Juice Shop; ZAP records every request.

The container image is headless — there is no desktop UI and no web UI on any port. You get
at the recorded traffic two ways:

**A. The REST API** (what the script prints, and what CI uses). You talk to the API on
`localhost:8080`, but **every `url=`/`baseurl=` you pass names a target the ZAP container
must reach itself** — and inside that container `localhost` is the container, not your
laptop. Use `host.docker.internal:3000` (the same name the baseline/full scripts use), not
`localhost:3000`:

```bash
$ curl -s "http://localhost:8080/JSON/core/view/sites/" | jq
$ curl -s "http://localhost:8080/JSON/ascan/action/scan/?url=http://host.docker.internal:3000/rest/products/search&recurse=false"
$ curl -s "http://localhost:8080/JSON/core/view/alerts/?baseurl=http://host.docker.internal:3000" \
    | jq -r '.alerts[] | "\(.risk)\t\(.alert)\t\(.url)"' | sort -u
```

> ⚠️ **Verified the hard way (2026-08-21, Docker Desktop for Mac).** Spidering
> `url=http://localhost:3000` from the containerized daemon returns only ZAP's auto-seeded
> `robots.txt`/`sitemap.xml` — it never fetches a single app asset, because the container has
> nothing on its own port 3000. The same spider against `host.docker.internal:3000` finds
> `styles.css`, the favicon, `/ftp`, etc. The daemon is only worth driving over the API for
> **scan actions** (spider/ascan) against `host.docker.internal:3000`.

**B. ZAP Desktop** (`brew install --cask zap`, or the official installers) — the smoother
path on macOS for the interactive "browse Juice Shop through the proxy" loop, because a
**native** proxy resolves `localhost:3000` the same way your browser does (the containerized
proxy above cannot). You get the point-and-click workflow the tutorials show: right-click a
request → **Attack → Active scan**, right-click a parameter → **Fuzz**, replay via the
**Manual Request Editor**. Point the desktop app at the same proxy port, or just use it as
the proxy directly.

Either way, the loop is the same and it is the core DAST workflow: browse as a user →
inspect what the client actually sent → change one thing → replay → observe.

### Exercise 5 — Nuclei: fast templated scans

```bash
$ ./scripts/run-nuclei.sh -u http://localhost:3000 -severity medium,high,critical
$ ./scripts/run-nuclei.sh -u http://localhost:3000 -t http/exposures
$ ./scripts/run-nuclei.sh -u http://localhost:3000 -t http/cves -severity high,critical
```

Nuclei is template-based — every check is a YAML file. Browse [`projectdiscovery/nuclei-templates`](https://github.com/projectdiscovery/nuclei-templates) to see the catalog.

Don't expect a wall of findings — Juice Shop's bugs are logic/injection flaws, not the
known-CVE fingerprints Nuclei matches. Measured on 2026-08-21 (nuclei v3.3.4, templates
v10.4.7, `-severity medium,high,critical`): **one** match, `prometheus-metrics` — an exposed
`/metrics` endpoint. That single hit is the point: Nuclei is precise, not exhaustive.

> ℹ️ `run-nuclei.sh` uses `docker run --network host`, so `-u http://localhost:3000` reaches
> the app directly (verified on Docker Desktop for Mac 29.x). If your Docker build lacks host
> networking and every request errors, run Nuclei natively (`brew install nuclei`) — the
> script prefers a host `nuclei` binary when one is on `PATH`.

> 💡 **DAST vs Nuclei.** ZAP is exploratory and great at finding logic bugs by behaving like a browser. Nuclei is specific — "is this CVE present at this URL." You want both in CI.

### Exercise 6 — SQL injection deep-dive

Use ZAP proxy + the login endpoint. Submit `admin@juice-sh.op' --` as the email, anything as password. Watch the request in ZAP, see how the backend returns success.

Now look at the code in [`bkimminich/juice-shop`](https://github.com/juice-shop/juice-shop) — `routes/login.ts` literally interpolates the email into a SQL string. The fix is parameterized queries (`$1`, `$2`).

> 🔁 **Tie it back to lab 03.** Semgrep should flag this exact pattern. Run lab 03's `no-sql-concat` rule against the Juice Shop source if you cloned it — it catches the same bug statically.

### Exercise 7 — XSS payload variations

The **search box** is the reliable DOM-XSS sink in this build: the search-result component
binds your term with `[innerHTML]` after `bypassSecurityTrustHtml()` (you'll read that exact
code in Exercise 8). Because that binding runs `innerHTML`, the classic payload is an
`<iframe>` with a `javascript:` URL — an inline `<script>` inserted via `innerHTML` does not
execute, so this is the one that fires (in the lab only):

```html
<iframe src="javascript:alert(`xss`)">
```

Then experiment with variants ZAP or a sanitizer might mishandle:

```html
<img src=x onerror="alert('xss')">
<svg/onload="alert('xss')">
```

> ⚠️ **Do not expect ZAP to auto-confirm this for you.** Re-running the active scan does
> **not** surface the XSS: the vulnerable sink is client-side DOM (`bypassSecurityTrustHtml`
> → `innerHTML`) reached through the SPA's JS, and an unauthenticated ZAP full scan never
> drives that path (see Exercise 3 — it finds no XSS at all here, verified 2026-08-21). This
> is a *find-it-by-hand-in-the-browser* exercise. To make a scanner reach it you'd need ZAP's
> AJAX spider plus a DOM-XSS active rule, or ZAP Desktop's browser-driven scan — automation
> is possible, but it is not the free result the old wording promised.

### Exercise 8 — Fix one vulnerability end-to-end

Pick **DOM XSS in the search box**:

1. Reproduce it **in the browser** with the `<iframe src="javascript:...">` payload from
   Exercise 7 (this is a client-side DOM sink; the automated ZAP scan does not flag it, so
   the browser is your oracle here)
2. Read the offending Angular code — component template
   `frontend/src/app/search-result/search-result.component.html` binds `[innerHTML]="searchValue"`,
   and the component sets `searchValue = this.sanitizer.bypassSecurityTrustHtml(...)`
   (`search-result.component.ts`), which deliberately turns Angular's built-in sanitizer off
3. Note the `[innerHTML]` binding fed by a `bypassSecurityTrustHtml()` value — the exact
   anti-pattern
4. The fix: drop `bypassSecurityTrustHtml` and interpolate the term as text (`{{ searchValue }}`
   / `[textContent]`), or run it through `DomSanitizer.sanitize(SecurityContext.HTML, ...)`
5. Verify **in the browser**: the same payload now renders as inert text instead of executing

You don't have to push the fix; the point is to walk the loop **find → understand → fix → verify**.

### Exercise 9 — Close the loop for real: harden and rescan

Fixing Juice Shop's application bugs means rebuilding Juice Shop. But an entire *category*
of baseline findings — the missing response headers — can be fixed in front of the app,
which is exactly how it is usually done in production (edge proxy, ingress, CDN).

Baseline the unfixed app first, if you haven't already:

```bash
$ ./scripts/zap-baseline.sh
$ jq '[.site[].alerts[]] | length' exercises/zap-baseline.json
```

Bring up the same Juice Shop behind a header-hardening nginx (read
`hardened/nginx.conf` — every header there maps to one of the findings above):

```bash
$ docker compose --profile hardened up -d hardened
$ curl -sI localhost:3010 | grep -iE 'content-security|x-frame|x-content|referrer|permissions|cross-origin'
```

Rescan through the proxy and diff:

```bash
$ NAME=zap-hardened TARGET=http://host.docker.internal:3010 ./scripts/zap-baseline.sh
$ jq '[.site[].alerts[]] | length' exercises/zap-hardened.json

$ diff <(jq -r '.site[].alerts[].alert' exercises/zap-baseline.json | sort -u) \
       <(jq -r '.site[].alerts[].alert' exercises/zap-hardened.json  | sort -u)
```

> ✅ **Measured 2026-08-21 (`juice-shop:v17.3.0`, ZAP 2.17.0):** the diff removes exactly two
> alerts — `Content Security Policy (CSP) Header Not Set` and
> `Cross-Origin-Opener-Policy Header Missing`. That's it. The clickjacking and
> `X-Content-Type-Options` alerts do **not** disappear for the honest reason that they were
> never there: Juice Shop already sends `X-Frame-Options` and `nosniff` (Exercise 2).
>
> And here's the wrinkle worth the whole exercise: the total alert count goes **up**, from 13
> to 15. Adding a CSP means ZAP now grades the CSP's *content*, and the policy in
> `nginx.conf` is deliberately permissive — it has to allow `unsafe-inline`/`unsafe-eval` or
> Juice Shop's Angular bundle won't run — so four new lower-severity alerts appear
> (`CSP: unsafe-inline`, `CSP: unsafe-eval`, `CSP: Wildcard Directive`, ...). The
> `Cross-Origin-Embedder-Policy` and `Cross-Domain Misconfiguration (ACAO: *)` findings also
> survive, because the nginx config adds neither COEP nor a corrected CORS header.
>
> Meanwhile the **SQL injection, the XSS, the broken access control and the exposed `/ftp`
> directory are all exactly as exploitable as before.** That is the honest summary of header
> hardening: it is cheap, worth doing, and closes a couple of rows — while sometimes opening
> others, and never touching a single bug that lets someone take the application over. Any
> tool, dashboard or consultant that grades you on the count rather than on which findings
> closed is measuring the wrong thing.

One finding you cannot close here: `Strict-Transport-Security` is absent on purpose.
Browsers ignore HSTS on plain HTTP, so adding the header would satisfy the scanner while
changing nothing. The real fix is TLS, which this lab does not terminate. **Scanner-clean is
not the same as fixed**, and knowing when to leave a finding open is the skill.

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

### What DAST cannot see

DAST tests the surface it can reach. Everything below is invisible to an unauthenticated
baseline scan, and most of it is invisible to a full scan too:

- anything behind a login it cannot perform (which is most of the application)
- second-order bugs — a payload stored now and rendered on an admin page tomorrow
- business-logic flaws: negative quantities, price tampering, IDOR between two accounts it
  does not have
- anything reachable only from an unlinked endpoint (spiders follow links; they do not guess
  `/api/internal/v2/users`)
- the *cause*: DAST names a URL, never a line of code

Which is why "the DAST run was clean" is a statement about the scanner's coverage, not
about the app. Pair it with SAST (lab 03), SCA (lab 01) and an authenticated scan
(challenge 1).

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
- [ZAP API reference](https://www.zaproxy.org/docs/api/) — driving the daemon from exercise 4

➡️ Next: [Lab 06 — Kubernetes Security](../06-kubernetes-security/)
