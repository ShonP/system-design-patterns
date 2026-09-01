#!/usr/bin/env bash
# ZAP Baseline = spider + PASSIVE scan against a running app. Fast (2-5 min), safe:
# it never sends an attack payload, it only reads what the app volunteers.
#
#   ./scripts/zap-baseline.sh                                  # scans Juice Shop
#   NAME=zap-hardened TARGET=http://host.docker.internal:3010 ./scripts/zap-baseline.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p exercises

TARGET="${TARGET:-http://host.docker.internal:3000}"
NAME="${NAME:-zap-baseline}"

# The ZAP container writes reports as its own uid into /zap/wrk. On Linux that fails
# unless the directory is writable by it; 0777 on a throwaway report dir is fine.
chmod 0777 exercises 2>/dev/null || true

# --add-host: host.docker.internal is built in on Docker Desktop but NOT on Linux.
docker run --rm \
  --add-host=host.docker.internal:host-gateway \
  -v "$(pwd)/exercises":/zap/wrk:rw \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t "$TARGET" \
  -r "${NAME}.html" \
  -J "${NAME}.json" \
  -I || true   # zap-baseline exits 2 when it has warnings; we want the report regardless

echo "Reports: exercises/${NAME}.html  exercises/${NAME}.json"
