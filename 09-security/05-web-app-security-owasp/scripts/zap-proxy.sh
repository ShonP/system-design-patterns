#!/usr/bin/env bash
# Run ZAP as an intercepting proxy on :8080 for interactive testing.
#
# This is the HEADLESS daemon: there is no desktop UI and no web UI behind it.
# You drive it either through your browser (proxying traffic through it) or through
# its REST API. If you want the point-and-click "right-click -> Attack -> Active scan"
# workflow, install ZAP Desktop instead:  brew install --cask zap
set -euo pipefail

PORT="${ZAP_PORT:-8080}"

cat <<EOF2
Starting ZAP daemon on :${PORT} (proxy + REST API, no GUI).

  1. Point your BROWSER (not the whole laptop) at HTTP/HTTPS proxy localhost:${PORT}
     -- a separate Firefox profile is the least painful way.
  2. With that proxy active, visit http://zap/  -> "Download the ZAP Root CA" -> trust it.
     (http://zap/ is served BY the proxy; it does not resolve without it.)
  3. Browse Juice Shop normally. ZAP records every request in its site tree.
  4. Drive it over the API, e.g. (NOTE: the target URL is resolved from INSIDE this
     container, so use host.docker.internal:3000 -- 'localhost' there is the container,
     not your laptop, and will reach nothing):
       curl "http://localhost:${PORT}/JSON/core/view/sites/"
       curl "http://localhost:${PORT}/JSON/spider/action/scan/?url=http://host.docker.internal:3000"
       curl "http://localhost:${PORT}/JSON/ascan/action/scan/?url=http://host.docker.internal:3000&recurse=true"
       curl "http://localhost:${PORT}/JSON/core/view/alerts/?baseurl=http://host.docker.internal:3000"
     The API key is disabled below, so these need no auth. Never do that on a
     network anyone else can reach.

Ctrl-C to stop.
EOF2

docker run --rm -it \
  --add-host=host.docker.internal:host-gateway \
  -p "${PORT}:8080" \
  ghcr.io/zaproxy/zaproxy:stable \
  zap.sh -daemon -host 0.0.0.0 -port 8080 \
         -config api.disablekey=true \
         -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true
