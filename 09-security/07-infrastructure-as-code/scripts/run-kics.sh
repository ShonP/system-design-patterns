#!/usr/bin/env bash
set -euo pipefail
if command -v kics >/dev/null 2>&1; then exec kics scan "$@"; fi
exec docker run --rm -v "$(pwd)":/path -w /path checkmarx/kics:v2.1.5 scan "$@"
