#!/usr/bin/env bash
set -euo pipefail
if command -v checkov >/dev/null 2>&1; then exec checkov "$@"; fi
exec docker run --rm -v "$(pwd)":/tf -w /tf bridgecrew/checkov:3.2.334 "$@"
