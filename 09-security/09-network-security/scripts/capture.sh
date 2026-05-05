#!/usr/bin/env bash
# Capture N seconds of traffic on the lab network into exercises/capture.pcap
set -euo pipefail
N="${1:-30}"
mkdir -p exercises
docker compose exec -T attacker bash -lc "
  tshark -i eth0 -a duration:${N} -w /workspace/exercises/capture.pcap >/dev/null
"
echo "wrote exercises/capture.pcap"
