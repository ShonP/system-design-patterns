#!/usr/bin/env bash
# Install exercises/custom-rules.xml -- plus any extra rule files passed as arguments --
# as the manager's local ruleset.
#
#   ./scripts/install-custom-rules.sh                                        # exercise 7
#   ./scripts/install-custom-rules.sh exercises/sigma/suspicious-curl.wazuh.xml   # + ex 8
#
# The manager reads exactly one local ruleset file, so extra files are concatenated
# rather than copied alongside.
set -euo pipefail
cd "$(dirname "$0")/.."

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cat exercises/custom-rules.xml "$@" > "$TMP"
docker compose cp "$TMP" wazuh.manager:/var/ossec/etc/rules/local_rules.xml

# `docker compose cp` keeps the HOST file's uid/gid and mode. On macOS that lands as
# something like `-rw------- 501 games`, and wazuh-analysisd (running as `wazuh`) then
# logs a WARNING nobody reads and loads no rules at all:
#   (1103): Could not open file 'etc/rules/local_rules.xml' due to [(13)-(Permission denied)]
# The restart succeeds, the script prints "installed", and the exercise silently fails.
docker compose exec -T wazuh.manager chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml
docker compose exec -T wazuh.manager chmod 660 /var/ossec/etc/rules/local_rules.xml

docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-control restart >/dev/null

# Verify the rules actually loaded instead of trusting the restart.
sleep 5
# tail only -- ossec.log keeps warnings from earlier, already-fixed runs.
if docker compose exec -T wazuh.manager \
     sh -c "tail -40 /var/ossec/logs/ossec.log | grep -q \"Could not open file 'etc/rules/local_rules.xml'\""; then
  echo "!! analysisd still cannot read local_rules.xml -- check ownership above" >&2
fi
echo "==> Custom rules installed. Confirming rule 100100 is live:"
printf '%s\n' '{"event":"jwt_validation_failed","srcip":"10.1.2.3","user":"probe"}' \
  | docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-logtest 2>&1 \
  | grep -E "^\s+(id|description):" || echo "    (rule did not match -- see wazuh-logtest output)"
