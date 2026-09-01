#!/usr/bin/env bash
# ZAP Full scan = spider + AJAX spider + ACTIVE scan. Slow (10-30 min) and it really
# does send attack payloads. Lab targets only.
#
#   ./scripts/zap-full.sh
#   NAME=zap-full-hardened TARGET=http://host.docker.internal:3010 ./scripts/zap-full.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p exercises

TARGET="${TARGET:-http://host.docker.internal:3000}"
NAME="${NAME:-zap-full}"

chmod 0777 exercises 2>/dev/null || true

docker run --rm \
  --add-host=host.docker.internal:host-gateway \
  -v "$(pwd)/exercises":/zap/wrk:rw \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py \
  -t "$TARGET" \
  -r "${NAME}.html" \
  -J "${NAME}.json" \
  -I || true

echo "Reports: exercises/${NAME}.html  exercises/${NAME}.json"
