#!/usr/bin/env bash
set -euo pipefail
if command -v tfsec >/dev/null 2>&1; then exec tfsec "$@"; fi
exec docker run --rm -v "$(pwd)":/src -w /src aquasec/tfsec:v1.28.14 "$@"
