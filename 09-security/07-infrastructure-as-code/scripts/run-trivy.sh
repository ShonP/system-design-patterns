#!/usr/bin/env bash
set -euo pipefail
if command -v trivy >/dev/null 2>&1; then exec trivy "$@"; fi
exec docker run --rm -v "$(pwd)":/workspace -w /workspace -v trivy-cache:/root/.cache aquasec/trivy:0.58.1 "$@"
