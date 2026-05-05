#!/usr/bin/env bash
# Run a command inside the attacker container.
set -euo pipefail
docker compose exec -T attacker bash -lc "$*"
