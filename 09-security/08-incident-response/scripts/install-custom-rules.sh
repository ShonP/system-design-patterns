#!/usr/bin/env bash
set -euo pipefail
docker compose cp exercises/custom-rules.xml wazuh.manager:/var/ossec/etc/rules/local_rules.xml
docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-control restart
echo "==> Custom rules installed."
