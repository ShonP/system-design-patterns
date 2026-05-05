#!/usr/bin/env bash
# Generate failed-sudo events on the victim — should fire built-in rule 5710.
set -euo pipefail
echo "==> Failing 'sudo -u root' as alice 20 times..."
for i in $(seq 1 20); do
  docker compose exec -T -u alice victim bash -lc "echo wrong | sudo -S -u root id 2>/dev/null || true"
done
echo "==> Done. Check dashboard for rule.id 5710 / 5712."
