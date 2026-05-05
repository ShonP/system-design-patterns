#!/usr/bin/env bash
set -euo pipefail
URL=${1:-http://localhost:3002/api/login}
N=${2:-15}
for i in $(seq 1 "$N"); do
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
    -H 'content-type: application/json' -d '{"u":"a","p":"b"}')
  echo "request $i -> $code"
done
