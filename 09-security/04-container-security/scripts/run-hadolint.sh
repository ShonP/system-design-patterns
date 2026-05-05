#!/usr/bin/env bash
set -euo pipefail
if command -v hadolint >/dev/null 2>&1; then
  exec hadolint "$@"
fi
exec docker run --rm -i hadolint/hadolint:v2.12.0 hadolint - < "$1"
