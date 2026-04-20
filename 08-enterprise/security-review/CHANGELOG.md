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
