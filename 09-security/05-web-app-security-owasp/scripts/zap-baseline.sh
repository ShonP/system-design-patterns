#!/usr/bin/env bash
# ZAP Baseline = passive scan against a running app. Fast, safe.
set -euo pipefail
mkdir -p exercises
TARGET="${TARGET:-http://host.docker.internal:3000}"
docker run --rm \
  -v "$(pwd)/exercises":/zap/wrk \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t "$TARGET" \
  -r zap-baseline.html \
  -J zap-baseline.json \
  -I || true   # exit 2 on warnings; we want the report regardless
echo "Reports: exercises/zap-baseline.html  exercises/zap-baseline.json"
