#!/usr/bin/env bash
set -euo pipefail
if command -v trufflehog >/dev/null 2>&1; then
  exec trufflehog "$@"
fi
exec docker run --rm -v "$(pwd)":/workspace -w /workspace trufflesecurity/trufflehog:3.97.0 "$@"
