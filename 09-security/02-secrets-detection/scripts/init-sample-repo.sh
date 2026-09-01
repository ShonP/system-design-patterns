#!/usr/bin/env bash
# Build a small git repo with planted (fake) secrets across multiple commits.
# Re-runnable: deletes and rebuilds sample-repo/ from scratch.
#
# Every value below is freshly generated at run time or a vendor's published test value.
# None of them authenticate to anything. They are shaped like the real thing on purpose:
# a scanner that only fires on documentation placeholders teaches you nothing (see the
# canary in apps/web/config.json, which most scanners deliberately ignore).
#
# The values are generated rather than written into this script because a correctly
# shaped credential in a committed file is a credential to GitHub's push protection,
# which blocks the push. See 09-security/scripts/fake-secrets.sh.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
REPO="$ROOT/sample-repo"

source "$(cd ../scripts && pwd)/fake-secrets.sh"

AWS_KEY_ID=$(fake_aws_access_key_id)
AWS_SECRET=$(fake_aws_secret_access_key)
SLACK_URL=$(fake_slack_webhook_url)
DB_PASSWORD=$(fake_password)
STRIPE_KEY=$(fake_stripe_secret_key)
JWT_SECRET=$(fake_jwt_secret)
SENDGRID_KEY=$(fake_sendgrid_api_key)
GITHUB_PAT=$(fake_github_pat)

rm -rf "$REPO"
mkdir -p "$REPO/apps/web" "$REPO/apps/api" "$REPO/configs" "$REPO/scripts"
cd "$REPO"

git init -q -b main
git config user.email "dev@security-labs.local"
git config user.name  "Dev"

# Commit 1 — the original sin: hardcoded AWS keys in a config file.
# Note the two access keys: one freshly generated, one AWS's published documentation
# example (kept literal on purpose — the whole point is that scanners allowlist it).
# Only the first one is reported. That is exercise 1's punchline.
cat > apps/web/config.json <<JSON
{
  "aws": {
    "accessKey": "$AWS_KEY_ID",
    "secretKey": "$AWS_SECRET",
    "region":    "us-east-1"
  },
  "_docs": {
    "example_accessKey": "AKIAIOSFODNN7EXAMPLE",
    "example_secretKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  },
  "feature_flags": { "newCheckout": true }
}
JSON
git add . && git commit -q -m "initial commit"

# Commit 2 — adds a Slack webhook (correctly shaped: /services/T.../B.../24-char token)
cat > apps/api/notify.js <<JS
const SLACK = "$SLACK_URL";
module.exports = { SLACK };
JS
git add . && git commit -q -m "feat: slack notifications"

# Commit 3 — a .env with a Stripe test key, a SendGrid key and a DB URL
cat > .env.production <<ENV
DATABASE_URL=postgres://app:$DB_PASSWORD@db.internal:5432/prod
STRIPE_KEY=$STRIPE_KEY
JWT_SECRET="$JWT_SECRET"
SENDGRID_API_KEY=$SENDGRID_KEY
ENV
git add . && git commit -q -m "chore: prod env vars (REVERT ME)"

# Commit 4 — the "fix": delete the .env. The secrets are still in history, and were
# already compromised the moment this branch was pushed.
git rm -q .env.production
git commit -q -m "chore: remove env file from repo"

# Commit 5 — adds a GitHub PAT in a script
cat > scripts/release.sh <<SH
#!/usr/bin/env bash
GH_TOKEN=$GITHUB_PAT
curl -H "Authorization: token \$GH_TOKEN" https://api.github.com/repos/example/example
SH
chmod +x scripts/release.sh
git add . && git commit -q -m "ci: add release script"

# Commit 6 — innocent-looking commit that touches the same file (drift!)
sed -i.bak 's/example\/example/example\/secure-app/g' scripts/release.sh && rm scripts/release.sh.bak
git add . && git commit -q -m "ci: point release script at new repo"

# Empty configs/ directory marker for exercise 4 (custom rule)
touch configs/.gitkeep && git add configs/.gitkeep && git commit -q -m "chore: configs dir"

cat <<EOF

✅ sample-repo built at: $REPO
$(git -C "$REPO" log --oneline)

Planted (fake) secrets:
  HEAD (working tree):
    - AWS access key + secret key          apps/web/config.json
    - AWS documentation canary (IGNORED    apps/web/config.json  <- exercise 1
      by most scanners' default allowlist)
    - Slack incoming webhook URL           apps/api/notify.js
    - GitHub PAT (ghp_...)                 scripts/release.sh
  History only (deleted in commit 4):
    - Stripe live-shaped key, SendGrid key, JWT secret, DB password   .env.production

All values are generated fresh on each run or vendor-published test values.
They authenticate to nothing.
EOF
