#!/usr/bin/env bash
# One-time Wazuh certificate generation + bring up the stack.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f certs/root-ca.pem ]]; then
  echo "==> Generating Wazuh certificates (one-time, ~30s)..."
  mkdir -p certs
  # The generator reads the node list from /config/certs.yml and writes the whole set
  # into /certificates/wazuh-certificates/. Without the config mount it generates
  # NOTHING and exits 0 -- which is why the old version of this script appeared to work
  # and then failed at `docker compose up` with missing bind mounts.
  docker run --rm \
    -v "$(pwd)/config/certs.yml":/config/certs.yml:ro \
    -v "$(pwd)/certs":/certificates \
    wazuh/wazuh-certs-generator:0.0.2

  # Flatten: compose expects ./certs/wazuh.manager.pem, not ./certs/wazuh-certificates/...
  if [[ -d certs/wazuh-certificates ]]; then
    mv certs/wazuh-certificates/* certs/
    rmdir certs/wazuh-certificates
  fi
  chmod 644 certs/*.pem
  chmod 600 certs/*-key.pem
fi

echo "==> Certificates present:"
ls -1 certs

MISSING=0
for f in root-ca.pem admin.pem admin-key.pem \
         wazuh.manager.pem wazuh.manager-key.pem \
         wazuh.indexer.pem wazuh.indexer-key.pem \
         wazuh.dashboard.pem wazuh.dashboard-key.pem; do
  [[ -f "certs/$f" ]] || { echo "MISSING certs/$f" >&2; MISSING=1; }
done
if [[ $MISSING -eq 1 ]]; then
  echo "Certificate generation failed. Delete ./certs and re-run; if it still fails, the" >&2
  echo "upstream single-node deployment is the reference: https://github.com/wazuh/wazuh-docker" >&2
  exit 1
fi

echo "==> Bringing up the stack..."
docker compose up -d

echo "==> Waiting for the stack to become usable (this is the slow part)..."
./scripts/wait-for-stack.sh

cat <<'MSG'

✅ Wazuh stack ready.

   Dashboard: https://localhost:8443   (self-signed cert -- click through the warning)
   user: admin    pass: SecretPassword

   Those credentials come from config/wazuh_indexer/internal_users.yml, which this
   compose mounts over the image's own copy. They are the public Wazuh demo hashes --
   keep this stack on localhost.

The dashboard is optional for every exercise in this lab. Alerts are written to
/var/ossec/logs/alerts/alerts.json on the manager, and ./scripts/timeline.sh reads them
directly. Re-run ./scripts/wait-for-stack.sh any time to re-check health.
MSG
