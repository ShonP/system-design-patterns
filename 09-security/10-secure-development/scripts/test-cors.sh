#!/usr/bin/env bash
set -euo pipefail
URL=${1:-http://localhost:3002/api/me}
for origin in "https://app.example.com" "https://evil.com" "http://localhost:3002"; do
  echo "=== Origin: $origin ==="
  curl -sI -H "Origin: $origin" "$URL" | grep -iE '^(http|access-control|vary)' || true
  echo
done
