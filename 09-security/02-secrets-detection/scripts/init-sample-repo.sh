#!/usr/bin/env bash
# Build a small git repo with planted (fake) secrets across multiple commits.
# Re-runnable: deletes and rebuilds sample-repo/ from scratch.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
REPO="$ROOT/sample-repo"

rm -rf "$REPO"
mkdir -p "$REPO/apps/web" "$REPO/apps/api" "$REPO/configs" "$REPO/scripts"
cd "$REPO"

git init -q -b main
git config user.email "dev@security-labs.local"
git config user.name  "Dev"

# Commit 1 — the original sin: hardcoded AWS keys in a config file
cat > apps/web/config.json <<'JSON'
{
  "aws": {
    "accessKey": "AKIAIOSFODNN7EXAMPLE",
    "secretKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
    "region":    "us-east-1"
  },
  "feature_flags": { "newCheckout": true }
}
JSON
git add . && git commit -q -m "initial commit"

# Commit 2 — adds a Slack webhook
cat > apps/api/notify.js <<'JS'
const SLACK = "https://hooks.slack.com/services/FAKE/WEBHOOK/FOR_LAB";
module.exports = { SLACK };
JS
git add . && git commit -q -m "feat: slack notifications"

# Commit 3 — adds a generic high-entropy token in a .env
cat > .env.production <<'ENV'
DATABASE_URL=postgres://app:hunter2@db.internal:5432/prod
JWT_SECRET=sk_live_EXAMPLE_FAKE_KEY_FOR_LAB
SENDGRID_API_KEY=SG.abcdefghijklmnop.qrstuvwxyz1234567890ABCDEF
ENV
git add . && git commit -q -m "chore: prod env vars (REVERT ME)"

# Commit 4 — "fix": delete the .env, but it's still in history
git rm -q .env.production
git commit -q -m "chore: remove env file from repo"

# Commit 5 — adds a fake GitHub PAT in a script
cat > scripts/release.sh <<'SH'
#!/usr/bin/env bash
GH_TOKEN=ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ012345abcd
curl -H "Authorization: token $GH_TOKEN" https://api.github.com/repos/example/example
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
  - AWS access + secret key (AKIA... EXAMPLE)         apps/web/config.json
  - Slack webhook URL                                  apps/api/notify.js
  - Stripe-looking JWT secret + SendGrid key (deleted) .env.production (history only)
  - GitHub PAT (ghp_...)                               scripts/release.sh

These are PUBLIC CANARY values — they don't authenticate to anything.
EOF
