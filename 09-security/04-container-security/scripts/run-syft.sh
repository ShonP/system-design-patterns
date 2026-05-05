#!/usr/bin/env bash
set -euo pipefail
if command -v syft >/dev/null 2>&1; then exec syft "$@"; fi
exec docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/workspace -w /workspace \
  anchore/syft:v1.18.1 "$@"
