#!/usr/bin/env bash
# One-time Wazuh certificate generation + bring up the stack.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -d certs ]]; then
  echo "==> Generating Wazuh certificates (one-time, ~30s)..."
  docker run --rm -v "$(pwd)/certs":/certificates \
    wazuh/wazuh-certs-generator:0.0.2 || true
  ls certs >/dev/null
fi

echo "==> Bringing up the stack (be patient — first boot takes 2–4 min)..."
docker compose up -d

cat <<'EOF'

✅ Wazuh stack starting. Default credentials:
   Dashboard URL: https://localhost:8443
   user: admin    pass: SecretPassword

Wait until `docker compose ps` shows wazuh.dashboard healthy, then log in.
EOF
