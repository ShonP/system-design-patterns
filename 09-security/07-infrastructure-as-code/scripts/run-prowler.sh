#!/usr/bin/env bash
# Prowler runner.
#
# By default this mounts NOTHING from your home directory: the catalog commands
# (--list-checks, --list-services, --list-compliance, --list-compliance-requirements)
# need no credentials at all, and that is the whole of Exercise 6a.
#
# To run a real posture scan against your own account, opt in explicitly:
#
#   PROWLER_MOUNT_AWS=1 ./scripts/run-prowler.sh aws --output-formats csv \
#       --output-directory /workspace/exercises/prowler/
#
# That mounts ~/.aws read-only so Prowler can use your CLI profile. Point it at an
# account you are allowed to sweep with 639 read-only checks.
#
# Pinned to 5.39.1: toniblyx/prowler:5.0.0 publishes linux/amd64 only and cannot be
# pulled on Apple Silicon at all. 5.39.1 is multi-arch.
set -euo pipefail
IMAGE="toniblyx/prowler:5.39.1"

if [[ "${PROWLER_MOUNT_AWS:-0}" == "1" ]]; then
  if [[ ! -d "${HOME}/.aws" ]]; then
    echo "PROWLER_MOUNT_AWS=1 but ${HOME}/.aws does not exist." >&2
    exit 1
  fi
  echo "==> mounting ${HOME}/.aws read-only into the container" >&2
  exec docker run --rm \
    -v "${HOME}/.aws":/home/prowler/.aws:ro \
    -v "$(pwd)":/workspace -w /workspace \
    "$IMAGE" "$@"
fi

exec docker run --rm \
  -v "$(pwd)":/workspace -w /workspace \
  "$IMAGE" "$@"
