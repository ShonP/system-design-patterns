#!/usr/bin/env bash
set -euo pipefail
helm repo add aqua https://aquasecurity.github.io/helm-charts/ >/dev/null
helm repo update >/dev/null
helm upgrade --install trivy-operator aqua/trivy-operator \
  --namespace trivy-system --create-namespace \
  --version 0.24.1 \
  --set trivy.ignoreUnfixed=true
kubectl rollout status -n trivy-system deploy/trivy-operator --timeout=120s
echo "Trivy Operator installed. Reports populate as workloads are deployed."
