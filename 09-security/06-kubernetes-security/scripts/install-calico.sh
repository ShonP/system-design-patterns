#!/usr/bin/env bash
# Install Calico so NetworkPolicies are actually enforced (exercise 5).
# Requires a cluster created with:  CNI=calico ./scripts/kind-up.sh
set -euo pipefail

if kubectl -n kube-system get daemonset kindnet >/dev/null 2>&1; then
  cat <<'MSG' >&2
kindnet is installed on this cluster. Two CNIs on one cluster is not a supported
configuration and the result is unpredictable networking, not a NetworkPolicy lab.

Recreate the cluster without a CNI first:

  ./scripts/kind-down.sh
  CNI=calico ./scripts/kind-up.sh
  ./scripts/install-calico.sh
MSG
  exit 1
fi

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
kubectl rollout status -n kube-system ds/calico-node --timeout=300s
kubectl wait --for=condition=Ready nodes --all --timeout=300s
echo "Calico installed; NetworkPolicy is now enforced."
