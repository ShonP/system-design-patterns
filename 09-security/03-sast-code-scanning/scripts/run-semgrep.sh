#!/usr/bin/env bash
# The published image is semgrep/semgrep. The old returntocorp/semgrep name is the
# pre-rename mirror and stopped receiving new tags -- don't copy it from old blog posts.
set -euo pipefail
# Semgrep phones home whenever --config pulls from the registry. Opt out by default;
# override with SEMGREP_SEND_METRICS=auto if you want the upstream default back.
: "${SEMGREP_SEND_METRICS:=off}"
export SEMGREP_SEND_METRICS
if command -v semgrep >/dev/null 2>&1; then
  exec semgrep "$@"
fi
exec docker run --rm -e SEMGREP_SEND_METRICS -v "$(pwd)":/src -w /src \
  semgrep/semgrep:1.96.0 semgrep "$@"
