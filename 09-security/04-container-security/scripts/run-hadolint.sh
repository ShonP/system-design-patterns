#!/usr/bin/env bash
# Lint a Dockerfile. Usage:
#   ./scripts/run-hadolint.sh insecure/Dockerfile
#   ./scripts/run-hadolint.sh --version
# The Docker fallback pipes the file in on stdin, so it needs a real file path --
# any argument starting with "-" is treated as a flag and forwarded as-is.
set -euo pipefail

if command -v hadolint >/dev/null 2>&1; then
  exec hadolint "$@"
fi

if [[ $# -eq 0 || ${1:-} == -* ]]; then
  exec docker run --rm hadolint/hadolint:v2.12.0 hadolint "$@"
fi

exec docker run --rm -i hadolint/hadolint:v2.12.0 hadolint "${@:2}" - < "$1"
