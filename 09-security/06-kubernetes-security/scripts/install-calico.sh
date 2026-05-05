#!/usr/bin/env bash
# Install Calico CNI on kind so NetworkPolicies are enforced.
set -euo pipefail
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
kubectl rollout status -n kube-system ds/calico-node --timeout=180s
echo "Calico installed."
