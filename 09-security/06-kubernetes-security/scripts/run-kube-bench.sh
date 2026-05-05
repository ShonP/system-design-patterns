#!/usr/bin/env bash
# Run kube-bench against the kind cluster. Mounts host paths read-only.
set -euo pipefail
docker run --rm --pid=host \
  -v /etc:/etc:ro \
  -v /var:/var:ro \
  -v "$(pwd)":/workspace -w /workspace \
  aquasec/kube-bench:v0.10.4 \
  --benchmark cis-1.24 run
