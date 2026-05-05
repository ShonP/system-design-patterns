#!/usr/bin/env bash
# ZAP Full scan = spider + active scan. Slow (10–30 min). Lab use only.
set -euo pipefail
mkdir -p exercises
TARGET="${TARGET:-http://host.docker.internal:3000}"
docker run --rm \
  -v "$(pwd)/exercises":/zap/wrk \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py \
  -t "$TARGET" \
  -r zap-full.html \
  -J zap-full.json \
  -I || true
echo "Reports: exercises/zap-full.html  exercises/zap-full.json"
