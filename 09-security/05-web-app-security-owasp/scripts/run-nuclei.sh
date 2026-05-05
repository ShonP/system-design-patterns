#!/usr/bin/env bash
set -euo pipefail
if command -v nuclei >/dev/null 2>&1; then exec nuclei "$@"; fi
exec docker run --rm \
  --network host \
  -v "$(pwd)":/workspace -w /workspace \
  -v nuclei-templates:/root/nuclei-templates \
  projectdiscovery/nuclei:v3.3.4 "$@"
