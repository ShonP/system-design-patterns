#!/usr/bin/env bash
# Mounts ~/.aws read-only if present so Prowler can use your CLI profile.
set -euo pipefail
ARGS=("$@")
if [[ -d "${HOME}/.aws" ]]; then
  exec docker run --rm \
    -v "${HOME}/.aws":/home/prowler/.aws:ro \
    -v "$(pwd)":/workspace -w /workspace \
    toniblyx/prowler:5.0.0 "${ARGS[@]}"
fi
exec docker run --rm \
  -v "$(pwd)":/workspace -w /workspace \
  toniblyx/prowler:5.0.0 "${ARGS[@]}"
