#!/usr/bin/env bash
# Pull the last hour of alerts from the manager and print as TSV.
set -euo pipefail
docker compose exec -T wazuh.manager bash -lc "
  tail -n 500 /var/ossec/logs/alerts/alerts.json
" | jq -r '
  [
    .timestamp,
    .agent.name,
    (.rule.id|tostring),
    (.rule.level|tostring),
    .rule.description
  ] | @tsv
'
