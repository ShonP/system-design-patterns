#!/usr/bin/env bash
set -euo pipefail
if command -v semgrep >/dev/null 2>&1; then
  exec semgrep "$@"
fi
exec docker run --rm -v "$(pwd)":/src -w /src returntocorp/semgrep:1.96.0 semgrep "$@"
