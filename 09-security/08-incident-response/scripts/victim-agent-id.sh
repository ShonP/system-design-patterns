#!/usr/bin/env bash
# Print the Wazuh agent ID of the "victim" agent.
#
# Do NOT hardcode 001. The manager hands out the next free ID at enrollment, and the
# victim re-enrolls every time its container is recreated (client.keys lives in the
# container filesystem, not in a volume). After one rebuild the victim is 002, then 003...
# Commands like `agent_control -r -u 001` silently print the usage text instead of running
# when the ID is wrong.
set -euo pipefail
cd "$(dirname "$0")/.."
ID=$(docker compose exec -T wazuh.manager /var/ossec/bin/agent_control -lc -s 2>/dev/null \
     | awk -F, '$2=="victim"{print $1; exit}')
if [[ -z "${ID:-}" ]]; then
  echo "victim agent is not registered/active -- see exercise 1 troubleshooting" >&2
  exit 1
fi
printf '%s\n' "$ID"
