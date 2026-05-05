#!/usr/bin/env bash
# Run ZAP as a proxy + Web UI for interactive testing.
#   - Proxy on  :8080  (configure your browser to use it)
#   - WebUI on  :8090  (open http://localhost:8090/zap/ in a browser)
set -euo pipefail

cat <<'EOF'
Starting ZAP proxy.

After it's up:
  1. Configure your BROWSER (not your whole laptop) to use HTTP/HTTPS proxy
     localhost:8080 — Firefox profile or Chrome SwitchyOmega.
  2. Visit http://zap/ in that browser → download CA cert → trust it.
  3. Browse Juice Shop normally; ZAP records every request.
  4. Open the WebUI at http://localhost:8090/zap/  to attack/replay.

Ctrl-C to stop.
EOF

docker run --rm -it \
  -p 8080:8080 -p 8090:8090 \
  ghcr.io/zaproxy/zaproxy:stable \
  zap.sh -daemon -host 0.0.0.0 -port 8080 \
         -config api.disablekey=true \
         -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true
