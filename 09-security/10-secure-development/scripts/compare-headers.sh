#!/usr/bin/env bash
set -euo pipefail

V=${VULN:-http://localhost:3001}
S=${SEC:-http://localhost:3002}

echo "=== vulnerable-app ($V) ==="
curl -sI "$V/" | grep -iE 'content-security|strict-transport|x-frame|x-content|referrer-policy|permissions-policy|cross-origin|x-powered-by' || echo "(no security headers)"

echo
echo "=== secure-app ($S) ==="
curl -sI "$S/" | grep -iE 'content-security|strict-transport|x-frame|x-content|referrer-policy|permissions-policy|cross-origin|x-powered-by' || echo "(no security headers)"
