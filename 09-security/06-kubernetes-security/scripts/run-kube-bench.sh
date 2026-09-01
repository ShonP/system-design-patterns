#!/usr/bin/env bash
# Audit the kind cluster's control plane against the CIS Kubernetes Benchmark.
# kube-bench runs as a Job on the control-plane node -- see manifests/kube-bench-job.yaml
# for why it cannot usefully run on your laptop.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl delete job kube-bench-master --ignore-not-found >/dev/null
kubectl apply -f manifests/kube-bench-job.yaml
echo "==> waiting for the job to finish (up to 3 min)..."
kubectl wait --for=condition=complete job/kube-bench-master --timeout=180s \
  || kubectl wait --for=condition=failed job/kube-bench-master --timeout=10s || true
kubectl logs job/kube-bench-master
echo
echo "Summary lines only:"
kubectl logs job/kube-bench-master | grep -E "^\s*(\[FAIL\]|\[WARN\])" | head -40 || true
echo
echo "Clean up with: kubectl delete job kube-bench-master"
