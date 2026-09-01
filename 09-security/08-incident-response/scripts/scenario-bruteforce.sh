#!/usr/bin/env bash
# Generate failed sudo authentications on the victim, then one that succeeds.
#
# The success at the end is the point. A pile of failures is background noise on any
# real host; failures *followed by a success from the same principal* is the finding,
# and exercise 5 needs that shape to build a timeline out of.
set -euo pipefail
echo "==> Failing 'sudo -u root id' as alice 20 times..."
for i in $(seq 1 20); do
  docker compose exec -T -u alice victim bash -lc "echo wrong | sudo -S -u root id 2>/dev/null || true"
done
echo "==> ...then succeeding once with the correct password."
docker compose exec -T -u alice victim bash -lc "echo alice | sudo -S -u root id"
echo "==> Done. Expect ~20 x rule 5503 (PAM: User login failed) and one successful-sudo"
echo "    alert. Rule IDs 5710/5712 are SSHD rules and do NOT fire here -- there is no"
echo "    sshd on the victim."
