#!/usr/bin/env bash
set -euo pipefail
if command -v kubescape >/dev/null 2>&1; then exec kubescape "$@"; fi
exec docker run --rm \
  -v "$(pwd)":/workspace -w /workspace \
  -v "${HOME}/.kube":/root/.kube:ro \
  quay.io/kubescape/kubescape-cli:v3.0.22 "$@"
