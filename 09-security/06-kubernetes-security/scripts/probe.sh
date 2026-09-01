#!/usr/bin/env bash
# One-shot connectivity probe for exercise 5.
#
#   ./scripts/probe.sh                 # a pod with no labels
#   ./scripts/probe.sh app=frontend    # a pod that matches the allow-frontend policy
#
# Prints ALLOWED or BLOCKED.
#
# Why this is a script and not a bare `kubectl run --image=alpine`: the namespace under
# test enforces Pod Security `restricted`, and a default `kubectl run` pod violates it
# (runs as root, no seccomp profile, no dropped capabilities). It is rejected at
# admission, never starts, and never sends a packet -- which looks exactly like a
# NetworkPolicy block if you only read the exit code. The overrides below are the
# minimum that `restricted` accepts.
set -uo pipefail
NS="${NS:-good}"
TARGET="${TARGET:-web.good.svc.cluster.local:80}"
LABELS="${1:-}"
NAME="probe-$RANDOM"

overrides=$(cat <<JSON
{
  "metadata": { "labels": { $( [[ -n $LABELS ]] && printf '"%s": "%s"' "${LABELS%%=*}" "${LABELS#*=}" ) } },
  "spec": {
    "securityContext": {
      "runAsNonRoot": true, "runAsUser": 10001, "runAsGroup": 10001,
      "seccompProfile": { "type": "RuntimeDefault" }
    },
    "containers": [{
      "name": "probe",
      "image": "alpine:3.20",
      "command": ["sh","-c","wget -q -O- -T3 \$TARGET >/dev/null 2>&1 && echo ALLOWED || echo BLOCKED"],
      "env": [{ "name": "TARGET", "value": "${TARGET}" }],
      "securityContext": {
        "allowPrivilegeEscalation": false,
        "capabilities": { "drop": ["ALL"] }
      }
    }]
  }
}
JSON
)

kubectl run "$NAME" -n "$NS" --restart=Never --image=alpine:3.20 \
  --overrides="$overrides" --attach --rm --quiet 2>&1 | tail -1
