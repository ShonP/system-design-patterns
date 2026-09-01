#!/usr/bin/env bash
# Block until the whole stack is actually usable, and repair the one startup failure
# this deployment hits intermittently. Safe to re-run.
#
# Checks, in the order they become true:
#   1. manager   -- wazuh-analysisd and wazuh-remoted running (no analysisd = no alerts)
#   2. indexer   -- cluster health green on :9200
#   3. dashboard -- login page served on :8443
#   4. agent     -- "victim" listed Active by the manager
set -u
# NOTE: no `pipefail` here on purpose. `cmd | grep -q` makes grep exit as soon as it
# matches, cmd takes SIGPIPE, and with pipefail the whole pipeline reports failure -- so
# every check below would report "not ready" forever even on a perfectly healthy stack.
cd "$(dirname "$0")/.."

TIMEOUT=${TIMEOUT:-900}
T0=$SECONDS
el() { echo $(( SECONDS - T0 )); }

mgr_up()  { local o; o=$(docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-control status 2>/dev/null)
            case "$o" in *"wazuh-analysisd is running"*) return 0;; *) return 1;; esac; }
mgr_skeleton_ok() { docker compose exec -T wazuh.manager test -d /var/ossec/logs/alerts 2>/dev/null; }
idx_up()  { local o; o=$(curl -sk -u admin:SecretPassword --max-time 5 https://localhost:9200/_cluster/health 2>/dev/null)
            case "$o" in *'"status":"green"'*) return 0;; *) return 1;; esac; }
dash_up() { [ "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 8 https://localhost:8443/app/login 2>/dev/null)" = "200" ]; }
agent_up(){ local o; o=$(docker compose exec -T wazuh.manager /var/ossec/bin/agent_control -lc -s 2>/dev/null)
            case "$o" in *",victim,"*"Active"*) return 0;; *) return 1;; esac; }

##############################################################################
# Known failure: the manager comes up with only authd/wazuh-db/apid alive and
# /var/ossec/logs missing its alerts/ archives/ firewall/ subdirectories.
#
# The image keeps its real /var/ossec/logs tree in /var/ossec/data_tmp and the
# container's init script copies it into the volume ONLY if the mount looks empty
# (`find /var/ossec/logs -mindepth 1`). When the mount is not empty at that moment the
# copy is skipped, and wazuh-analysisd then dies on startup with
#   CRITICAL: (1107): Could not create directory 'logs/archives/2026/'
# taking remoted, logcollector and syscheckd with it. No alerts are ever produced and
# the agent sits on "Never connected" because nothing is listening on 1514.
#
# Observed on roughly half of cold boots on Docker Desktop for Mac. The fix is to throw
# away the half-initialised logs volume and let the manager initialise it properly. That
# discards /var/ossec/logs/alerts/alerts.json -- harmless, because this only triggers when
# the manager never produced an alert in the first place.
##############################################################################
repair_manager() {
  echo "==> Manager started without its logs skeleton (known intermittent init race)."
  echo "    Recreating wazuh.manager with a clean logs volume..."
  local vol
  vol=$(docker inspect "$(docker compose ps -q wazuh.manager)" \
        --format '{{range .Mounts}}{{if eq .Destination "/var/ossec/logs"}}{{.Name}}{{end}}{{end}}' 2>/dev/null)
  docker compose rm -sf wazuh.manager >/dev/null 2>&1
  [ -n "$vol" ] && docker volume rm "$vol" >/dev/null 2>&1
  docker compose up -d wazuh.manager >/dev/null 2>&1
  sleep 30
}

REPAIRED=0
while (( SECONDS - T0 < TIMEOUT )); do
  if mgr_up; then
    break
  fi
  if (( REPAIRED == 0 )) && (( SECONDS - T0 > 60 )) && ! mgr_skeleton_ok; then
    repair_manager; REPAIRED=1; T0=$SECONDS
  fi
  sleep 10
done
mgr_up && echo "t+$(el)s  manager: analysisd + remoted running" \
       || { echo "MANAGER NEVER CAME UP -- docker compose logs wazuh.manager" >&2; exit 1; }

for check in idx_up dash_up agent_up; do
  while (( SECONDS - T0 < TIMEOUT )); do $check && break; sleep 10; done
  case $check in
    idx_up)   $check && echo "t+$(el)s  indexer:   cluster green"        || echo "t+$(el)s  indexer:   NOT READY" ;;
    dash_up)  $check && echo "t+$(el)s  dashboard: https://localhost:8443" || echo "t+$(el)s  dashboard: NOT READY" ;;
    agent_up) $check && echo "t+$(el)s  agent:     victim Active"        || echo "t+$(el)s  agent:     NOT ENROLLED (see exercise 1)" ;;
  esac
done
