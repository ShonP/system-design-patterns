# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Added **Security Headers** section to `02_common_vulnerabilities.ipynb`
  (Content-Security-Policy, HSTS, X-Frame-Options, nosniff, Referrer-Policy,
  Permissions-Policy) with matching vulnerable + safe endpoints in the Flask app.
- Fixed `/api/login` vulnerable endpoint to actually compare the bcrypt password
  (it previously returned a token for any password) so the information-disclosure
  threat demo in notebook 1 is more realistic (404 vs 401 vs 200).
- Replaced the deprecated `safety check` with `pip-audit` in
  `04_security_gates_cicd.ipynb` and the example GitHub Actions workflow.
- Regenerated the seeded bcrypt password hash in `db/init.sql` so
  `password123` actually verifies.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.

## 2026-08-21 (correctness audit)
- **Fixed: the "safe" comments endpoint was still exploitable.** `show_comments_safe`
  HTML-escaped every field and then passed the finished string to
  `render_template_string()`, which compiles its argument as a Jinja template.
  `markupsafe.escape()` does not touch `{{` or `{%`, so a comment containing
  `{{7*191}}` was still **evaluated on the server** — server-side template injection
  in the endpoint the lab presents as the fix. It now returns the HTML via
  `make_response()`, with a comment explaining why escaping alone was never enough.
  Notebook 2 gained a matching before/after SSTI demo (asserted both ways), the
  vulnerable endpoint is now labelled as XSS *and* SSTI, and the notebook 4 DAST
  scanner tests for it as a regression control.
- **Fixed: the CSRF demo sent a request shape no browser can send.**
  `/api/transfer` read `request.json`, which raises **415** on a form-encoded body —
  and a cross-site `<form>` POST is always form-encoded. Both transfer endpoints now
  use `request.get_json(silent=True) or request.form`, and notebook 2's attack sends
  a form-encoded body with a session cookie and an `Origin: evil.com` header. Added
  the explanation of why a JSON-body demo is dishonest (CORS preflight would have
  blocked it) and an honest caveat that this endpoint has no session to forge.
- **Fixed: the SSRF demo probed `localhost` from inside the app container**, so two
  of its three "internal services" were simply connection-refused and the lesson
  never landed. It now probes the compose service names (`adminer:8080`,
  `redis:6379`), first shows that the *notebook* cannot resolve them, and
  distinguishes "nothing listening" from "port open but not HTTP".
- **Fixed: the notebook 3 secret scanner silently missed a planted secret.**
  `sk-[a-zA-Z0-9]{20,}` cannot match `sk-proj-...` (hyphen in position 4), so the
  modern OpenAI key format slipped through while the cell printed a confident count.
  Widened the character class, added a Shannon-entropy detector for unknown formats,
  tagged every planted secret in the fixture and added an assertion that all of them
  are caught with no false positives.
- **Fixed: the notebook 4 DAST scanner's `/safe` controls could never fail.**
  `test_sql_injection` `break`ed out of its loop as soon as the vulnerable endpoint
  reported a hit, so the "safe endpoint also vulnerable!" branch was dead code. Every
  check now probes the `/safe` twin unconditionally, and the cell asserts that all six
  expected vulnerabilities reproduce **and** that no `/safe` endpoint produced a
  finding. Dropped the `'; DROP TABLE products; --` payload (psycopg2 really does
  execute multiple statements) with a note on why scanners must not fire destructive
  payloads.
- **Fixed: numbers in prose disagreed with computed output.** The notebook 1 threat
  model document claimed "5 Critical, 3 High, 3 Medium" for a table holding 10 threats
  (5/2/3). Severity is no longer hand-assigned at all: each threat carries a
  likelihood and an impact, and severity is looked up in the `RISK_MATRIX` the
  markdown cell documents — so the drawn matrix is now the implementation instead of
  decoration. The counting cell asserts the resulting mix.
- **Fixed: the notebook 4 pipeline report invented its own numbers.** Gate 1 claimed
  "3 High, 2 Medium" and "SQL injection on line 45" while Bandit actually reports 2/2/1
  with B608 at line 65; the scan date was hardcoded to 2024-01-15. The report now
  derives every field from the gates the notebook ran, and asserts the pipeline blocks
  (an intentionally vulnerable app that passes every gate means the gates broke).
- **Fixed: broken CI examples.** The GitHub Actions workflow ran `uv sync` without
  installing uv, uploaded the Bandit artifact in a step that could never run (Bandit
  exits non-zero on findings), and called `docker-compose` (v1, gone from current
  runners). Now uses `astral-sh/setup-uv`, splits "produce report" from "gate" with
  `if: always()` on the upload, and uses `docker compose up -d --wait` — with a note
  that `--wait` is meaningless for `flask-app` until it declares a healthcheck.
- **Fixed: duplicated/garbled content from an earlier tool rename.** The Gate 2 tool
  table listed `pip-audit` twice, and the pipeline ASCII diagram had `pip-audit` in
  both lines of the Gate 2 box with the borders knocked out of alignment.
- **Fixed: `datetime.utcnow()`** (deprecated on 3.12, produces naive values) replaced
  with `datetime.now(timezone.utc)`; corrected Bandit's MD5 check ID from the retired
  **B303** to **B324** in the results table.
- **Added: STRIDE-per-element.** The model previously applied STRIDE only to
  endpoints — the easy half. Added the element-type applicability table (external
  entity S/R, process all six, data store T/R/I/D, data flow T/I/D), an assertion that
  no threat sits on a category its element type cannot have, four threats against the
  data stores and data flows the DFD already drew (unauthenticated Redis, over-broad
  DB role, deletable audit log, plaintext HTTP), and a coverage grid that prints the
  applicable-but-unexamined cells instead of hiding them.
- **Added: trust boundaries drawn on the DFD.** The section was titled "Trust
  Boundaries" but the diagram had none, and the prose claimed SQL injection "breaks"
  the Flask→Postgres boundary. Redrew the DFD with TB-1/TB-2/TB-3 marked, and
  rewrote the explanation: injection does not cross TB-2, it smuggles intent across
  TB-1 and reuses Flask's own privileges — which is why the fix lives at TB-1 and the
  containment at TB-2.
- **Added: closed the user-enumeration timing channel.** `login_safe` short-circuited
  on an unknown username, so it answered in microseconds for unknown users and a full
  bcrypt round for real ones — the notebook's claim that "an attacker can't tell if a
  username exists" was only true of the error message. It now always runs one bcrypt
  comparison, against a dummy hash when there is no user, and notebook 1 measures both
  channels (while being explicit that a handful of samples is not a statistical result).
- **Added: `allow_redirects=False`** to `fetch_url_safe` — an allowlisted host could
  answer `302 -> http://169.254.169.254/` and bypass every check above it — plus an
  honest note that DNS rebinding still defeats resolve-then-fetch validation.
- **Added: a verifiable review checklist.** The SDL sign-off checklist was ten nouns
  that everyone ticks. Replaced with a table of do-this / evidence-that-satisfies-it /
  fails-if, including the row that rejects a scan that ran but reached nothing.
- **Added: what the tools miss.** Notebook 4 now prints what Bandit did *not* find in
  this file (the XSS, the SSTI, the CSRF, the SSRF, and two of the three hardcoded
  secrets) so the SAST/DAST distinction is demonstrated rather than tabulated. The
  notebook 3 vault demo lists what a Redis-backed toy does not do that a real vault does.
- **Added: determinism.** Removed the `httpbin.org` dependency from notebook 1's
  endpoint check (now fully local), made notebook 2's one remaining network case
  tolerate an offline run without turning into a false security result, and made both
  login demos clear the Redis rate-limit counters first so a re-run sees 401s, not 429s.
- **Added: assertions throughout.** Every attack cell now fails loudly if it stops
  reproducing its own lesson, and every fix cell asserts both that the attack is
  blocked *and* that the feature still works (a `WHERE false` would pass the first
  check alone). Also fixed notebook 3's "Level N" headings, which numbered managed
  identities as Level 4 while the code demo called it Level 3.
