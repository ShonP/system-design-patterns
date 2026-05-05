#!/usr/bin/env bash
set -euo pipefail
if command -v bandit >/dev/null 2>&1; then
  exec bandit "$@"
fi
exec docker run --rm -v "$(pwd)":/src -w /src pyfound/bandit:1.7.10 bandit "$@"
