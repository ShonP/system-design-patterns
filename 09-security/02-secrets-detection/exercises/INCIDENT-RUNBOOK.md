# Leaked Secret Incident Runbook

When a secret is found in a public or shared repository, run this checklist **in order**. Speed matters — the average time-to-exploit for an exposed AWS key is measured in minutes.

## Step 0 — Triage (≤ 2 min)

- [ ] Is the secret **valid** (verifier returns OK / TruffleHog `Verified: true`)? If unverified, still treat as valid until proven otherwise.
- [ ] What does it grant access to? (Read-only? Admin? Production?)
- [ ] Where was it exposed? (Public repo? Private but with N collaborators? Container image on Docker Hub?)
- [ ] How long has it been exposed? (`git log -p` for the file)

## Step 1 — Rotate the credential FIRST (≤ 15 min)

> Do this before you clean up the repo. Rewriting history while a valid credential is in the wild is gardening during an arson.

| Type | How |
|---|---|
| AWS access key | IAM → Users → Security credentials → Make inactive → Delete. Issue a new one. |
| GCP service account key | IAM → Service accounts → Keys → Delete. Generate new. |
| Azure SP secret | App registrations → Certificates & secrets → Delete + regenerate. |
| GitHub PAT | github.com/settings/tokens → Revoke. |
| Slack webhook | Re-create the incoming webhook in the channel; update consumers. |
| Stripe key | Dashboard → Developers → API keys → Roll. |
| Database password | Rotate at the DB; update the consumer's secret store. |
| JWT signing secret | Rotate; **all existing tokens become invalid** — plan the rollout. |

## Step 2 — Investigate use (≤ 30 min)

Pull the audit log for the credential and look for unfamiliar IPs / actions during the exposure window.

```bash
# AWS example
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=AKIAxxx \
  --start-time 2025-04-01 --end-time 2025-05-05
```

If you see unauthorized use → escalate to your security incident process. **Do not** keep cleaning git history; preserve evidence.

## Step 3 — Clean up the repo

Once the credential is rotated, you can purge the secret from history:

```bash
# Recommended:
pip install git-filter-repo
git filter-repo --path apps/web/config.json --invert-paths
# or to redact a string everywhere:
git filter-repo --replace-text <(echo 'AKIAIOSFODNN7EXAMPLE==>REDACTED')
git push --force --all
git push --force --tags
```

Tell every collaborator to **re-clone**, not `git pull`. After a force-push, their local refs reference dead objects.

## Step 4 — Add controls so this can't recur

- [ ] Pre-commit hook (this lab, exercise 5)
- [ ] CI scanner job (exercise 6)
- [ ] GitHub push protection (org-level setting)
- [ ] Move the secret into a secret manager (Doppler / Vault / AWS Secrets Manager / 1Password Secrets Automation)
- [ ] Lock down the IAM role / service principal with least privilege so the next leak is less catastrophic

## Step 5 — Post-mortem

Write up: how it got committed, why scanners missed it (or didn't), what controls are now in place. Without this step you'll do this again in a quarter.
