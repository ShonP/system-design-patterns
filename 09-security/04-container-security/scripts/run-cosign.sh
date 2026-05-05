#!/usr/bin/env bash
set -euo pipefail
if command -v cosign >/dev/null 2>&1; then exec cosign "$@"; fi
exec docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/workspace -w /workspace \
  gcr.io/projectsigstore/cosign:v2.4.1 "$@"
