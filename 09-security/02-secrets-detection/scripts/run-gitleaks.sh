#!/usr/bin/env bash
set -euo pipefail
if command -v gitleaks >/dev/null 2>&1; then
  exec gitleaks "$@"
fi
exec docker run --rm -v "$(pwd)":/workspace -w /workspace zricethezav/gitleaks:v8.30.1 "$@"
