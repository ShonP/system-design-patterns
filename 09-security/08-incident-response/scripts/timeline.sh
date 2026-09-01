#!/usr/bin/env bash
# Print recent alerts from the manager as TSV: time, agent, rule id, level, description,
# and the one detail that usually identifies the event (file path, source IP, user).
# Reads alerts.json directly, so it works whether or not the indexer/dashboard came up.
#
# "Last 500 alerts", NOT "last hour" -- filter by timestamp yourself for a real window:
#   ./scripts/timeline.sh | awk -F'\t' '$1 > "2026-08-24T11:00"'
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose exec -T wazuh.manager bash -lc "
  tail -n 500 /var/ossec/logs/alerts/alerts.json 2>/dev/null
" | jq -r '
  [
    .timestamp,
    .agent.name,
    (.rule.id|tostring),
    (.rule.level|tostring),
    .rule.description,
    (.syscheck.path // .data.srcip // .data.dstuser // .data.event // "")
  ] | @tsv
'
