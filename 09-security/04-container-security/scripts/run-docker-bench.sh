#!/usr/bin/env bash
# Read-only audit of your Docker host against the CIS Docker Benchmark.
set -euo pipefail

# docker/docker-bench-security ships a Docker 18.06 client (API 1.38) and is unmaintained.
# Engine 25+ refuses any client below API 1.44, so without this pin every check that shells
# out to `docker` dies with "Error connecting to docker daemon (does docker ps work?)" and
# you get no output at all. 1.44 is the oldest API a modern daemon still accepts.
API_VERSION="${DOCKER_API_VERSION:-1.44}"

mounts=(-v /var/run/docker.sock:/var/run/docker.sock:ro)

if [[ "$(uname -s)" == "Linux" ]]; then
  # Sections 1 and 3 grade files belonging to the machine dockerd runs on. Only mount them
  # on a real Linux docker host. On Docker Desktop these paths are the *client* machine's,
  # and `-v /etc:/etc:ro` actually prevents the container from starting -- runc cannot
  # create the /etc/hostname mountpoint inside a read-only bind.
  for p in /etc /usr/bin/containerd /usr/bin/runc /usr/lib/systemd /var/lib; do
    if [[ -e "$p" ]]; then mounts+=(-v "$p:$p:ro"); fi
  done
else
  echo "note: non-Linux host -- skipping the /etc, /var/lib and systemd mounts." >&2
  echo "      Sections 1 and 3 will report 'File not found'. Sections 2, 4, 5 and 7 ask" >&2
  echo "      the daemon over the socket and are still valid. See exercise 6." >&2
fi

# The image is published for linux/amd64 only; naming the platform silences the mismatch
# warning on Apple silicon (it still runs under emulation).
exec docker run --rm --platform linux/amd64 \
  --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_API_VERSION="$API_VERSION" \
  -e DOCKER_CONTENT_TRUST="${DOCKER_CONTENT_TRUST:-}" \
  "${mounts[@]}" \
  --label docker_bench_security \
  docker/docker-bench-security
