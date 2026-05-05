#!/usr/bin/env bash
set -euo pipefail
docker compose exec -T wazuh.manager /var/ossec/bin/agent_control -lc || true
