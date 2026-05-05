#!/usr/bin/env bash
set -euo pipefail
NAME=seclabs

if ! command -v kind >/dev/null 2>&1; then
  echo "Install kind: brew install kind  (or https://kind.sigs.k8s.io/)"
  exit 1
fi
if kind get clusters | grep -q "^${NAME}$"; then
  echo "Cluster ${NAME} already exists. Use kind-down.sh to destroy."
  exit 0
fi

cat > /tmp/kind-${NAME}.yaml <<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: false
nodes:
  - role: control-plane
  - role: worker
  - role: worker
YAML

kind create cluster --name "${NAME}" --config /tmp/kind-${NAME}.yaml
kubectl cluster-info --context "kind-${NAME}"
