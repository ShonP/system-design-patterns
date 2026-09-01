#!/usr/bin/env bash
set -euo pipefail
URL=${1:-http://localhost:3002/api/me}
SELF=${SEC:-http://localhost:3002}          # the app's own origin, per ALLOWED_ORIGINS
for origin in "https://app.example.com" "https://evil.com" "$SELF"; do
  echo "=== Origin: $origin ==="
  curl -sI -H "Origin: $origin" "$URL" | grep -iE '^(http|access-control|vary)' || true
  echo
done
