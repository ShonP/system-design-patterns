#!/usr/bin/env bash
# Create the lab cluster.
#
#   ./scripts/kind-up.sh              # default CNI (kindnet): fine for exercises 1-4, 6-8
#   CNI=calico ./scripts/kind-up.sh   # no CNI installed; run install-calico.sh next
#
# Why the switch exists: kindnet -- kind's default CNI -- spent most of its life
# accepting NetworkPolicy objects and enforcing none of them. Recent builds DO enforce
# (measured: enforced on kindest/node:v1.36.1 with kind v0.32.0, 2026-08-24), so the
# default cluster is usually enough for exercise 5. CNI=calico is the escape hatch for
# when yours does not, and you cannot add Calico on top of kindnet: the cluster has to be
# created without a CNI.
set -euo pipefail
NAME=seclabs
CNI="${CNI:-kindnet}"
# Pinned so the numbers quoted in README.md are reproducible. Bump it deliberately, and
# re-measure the exercise output when you do; `NODE_IMAGE= ./scripts/kind-up.sh` uses
# whatever your kind binary defaults to.
NODE_IMAGE="${NODE_IMAGE-kindest/node:v1.36.1}"

if ! command -v kind >/dev/null 2>&1; then
  echo "Install kind: brew install kind  (or https://kind.sigs.k8s.io/)"
  exit 1
fi
if kind get clusters 2>/dev/null | grep -q "^${NAME}$"; then
  echo "Cluster ${NAME} already exists. Use kind-down.sh to destroy it first."
  echo "(Re-create with CNI=calico if you are starting exercise 5.)"
  exit 0
fi

if [[ $CNI == "calico" ]]; then
  DISABLE_CNI=true
  # Calico's stock manifest defaults its IP pool to 192.168.0.0/16; matching the cluster
  # pod subnet to it avoids having to patch CALICO_IPV4POOL_CIDR.
  POD_SUBNET="192.168.0.0/16"
else
  DISABLE_CNI=false
  POD_SUBNET="10.244.0.0/16"
fi

cat > "/tmp/kind-${NAME}.yaml" <<YAML
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: ${DISABLE_CNI}
  podSubnet: "${POD_SUBNET}"
nodes:
  - role: control-plane
  - role: worker
  - role: worker
YAML

kind create cluster --name "${NAME}" --config "/tmp/kind-${NAME}.yaml" \
  ${NODE_IMAGE:+--image "${NODE_IMAGE}"}
# `kind create` sets the current context, but say it out loud: every later script and
# every kubectl in the README talks to whatever the current context happens to be, and
# these labs plant deliberately vulnerable workloads. Point them at the wrong cluster once
# and you will not enjoy it.
kubectl config use-context "kind-${NAME}"
kubectl cluster-info --context "kind-${NAME}"

if [[ $CNI == "calico" ]]; then
  echo
  echo "Cluster created WITHOUT a CNI -- nodes will stay NotReady until you run:"
  echo "  ./scripts/install-calico.sh"
fi
