#!/usr/bin/env bash
# Bandit is a single pip package; the native path is by far the easiest:
#   uv tool install bandit   |   pipx install bandit   |   pip install bandit
# Docker fallback: the only image PyCQA publishes is ghcr.io/pycqa/bandit/bandit,
# and `latest` is its ONLY tag -- there is nothing to pin to, which is one more
# reason to prefer the native install. (pyfound/bandit on Docker Hub does not exist.)
# Its ENTRYPOINT is already `bandit`, so arguments are passed straight through.
set -euo pipefail
if command -v bandit >/dev/null 2>&1; then
  exec bandit "$@"
fi
exec docker run --rm -v "$(pwd)":/src -w /src ghcr.io/pycqa/bandit/bandit:latest "$@"
