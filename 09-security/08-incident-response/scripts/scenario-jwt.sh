#!/usr/bin/env bash
# Emit 6 fake JWT-failed events to /var/log/myapp.json on the victim.
set -euo pipefail
docker compose exec -T victim bash -lc '
  for i in 1 2 3 4 5 6; do
    echo "{\"event\":\"jwt_validation_failed\",\"srcip\":\"10.1.2.3\",\"user\":\"a$i\"}" >> /var/log/myapp.json
  done
'
echo "==> 6 events emitted. Custom rule 100101 should fire."
