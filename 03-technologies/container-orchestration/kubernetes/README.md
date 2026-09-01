# Kubernetes Enterprise Platform

📖 **What you'll learn**: How to build, deploy, secure, and operate a production-grade Kubernetes platform — from your first cluster to GitOps, service mesh, observability, and production hardening.

## The Problem

You need to run microservices in production. You need them to:

1. **Scale automatically** when traffic spikes
2. **Self-heal** when containers crash
3. **Roll out updates** without downtime
4. **Isolate teams** so one team can't break another's services
5. **Observe everything** — metrics, logs, traces
6. **Stay secure** — RBAC, network policies, and secrets that come from somewhere safer
   than a base64 string in etcd

Doing this manually with Docker on VMs doesn't scale. You need an **orchestration platform**.

**Kubernetes** is that platform. It's what powers Google, Netflix, Spotify, Airbnb, and most of the Fortune 500.

But Kubernetes has a steep learning curve. This lab series takes you from zero to production-ready, one concept at a time.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         minikube cluster                         │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ api-gateway   │───▶│ user-service  │    │ order-service │       │
│  │ (FastAPI)     │───▶│ (FastAPI)     │    │ (FastAPI)     │       │
│  │ port 8000     │    │ port 8001     │    │ port 8002     │       │
│  └──────┬───────┘    └──────────────┘    └──────────────┘       │
│         │                                                         │
│  ┌──────▼───────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ Ingress       │    │ Prometheus    │    │ ArgoCD        │       │
│  │ (NGINX)       │    │ + Grafana     │    │ (GitOps)      │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ Istio         │    │ RBAC +        │    │ PV/PVC        │       │
│  │ (mesh)        │    │ NetworkPolicy │    │ ConfigMaps    │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

## Notebooks in This Series

**Run them in order.** Each notebook checks that the previous one left the cluster in the
right state, and refuses to run with a clear error if it did not. Notebook 02 is the
hinge: it creates the `k8s-lab` namespace and the three sample services that notebooks
03–10 all build on.

Every section that *claims* an outcome also **asserts** it in Python. A `!kubectl ...`
line that exits non-zero prints red text but does not fail a notebook cell, so a demo
that quietly stopped reproducing its own lesson would otherwise look identical to one
that worked. If a rollout does not stall, an alert does not fire, a sidecar is not
injected or the autoscaler does not scale, the notebook stops there with a message
saying so.

| # | Notebook | What You'll Learn | Time |
|---|----------|-------------------|------|
| 1 | Cluster Setup | Install minikube + kubectl, create a right-sized cluster, read `kubectl describe` Events | 30 min |
| 2 | Pods & Deployments | Pods, Deployments, scaling, rolling updates (`maxSurge`/`maxUnavailable`), a rollout that fails and how rollback really works, requests vs limits, QoS classes, liveness/readiness/startup probes | 75 min |
| 3 | Services & Networking | ClusterIP, NodePort, LoadBalancer, headless, DNS, debugging an empty `Endpoints` list, Ingress with NGINX | 60 min |
| 4 | Helm & Kustomize | Package apps with Helm, values per environment, `helm history`/`rollback`, overlay configs with Kustomize | 45 min |
| 5 | Observability | metrics-server vs Prometheus, kube-prometheus-stack, ServiceMonitor, Grafana, alert rules that actually fire | 60 min |
| 6 | RBAC & Security | Namespaces, Role vs ClusterRole, NetworkPolicies (and whether your CNI enforces them), Pod Security Standards, quotas | 60 min |
| 7 | GitOps with ArgoCD | Install ArgoCD, sync from Git, auto-sync, self-heal, rollback via `git revert` | 45 min |
| 8 | Service Mesh | Install Istio, sidecar injection, mTLS, canary traffic splitting, retries/timeouts, Kiali | 60 min |
| 9 | Storage & Secrets | PV/PVC binding and access modes, a PVC that never binds, StorageClasses, StatefulSets, why Secrets are not encrypted | 60 min |
| 10 | Production Patterns | QoS classes, OOMKill vs CPU throttling (live), HPA, PodDisruptionBudgets, multi-tenancy, Velero | 75 min |

**Total estimated time: ~9.5 hours**

### What each notebook needs from the one before it

```
01  creates the minikube cluster
02  needs 01's cluster        -> creates namespace k8s-lab + 3 deployments
03  needs 02's deployments    -> creates the 3 Services (and an Ingress)
04  needs 02, 03
05  needs 02, 03              -> Services must exist; Prometheus discovers via Services
06  needs 02, 03
07  needs 02, 03
08  needs 02, 03
09  needs 02
10  needs 02, 03
```

Do not run `minikube delete` between notebooks. `minikube stop` / `minikube start` is
fine — it preserves everything.

## Key Concepts Covered

### 🏗️ Container Orchestration
Kubernetes manages the lifecycle of your containers — scheduling, scaling, healing, and networking — so you don't have to.

### 📦 Declarative Configuration
You describe your **desired state** in YAML manifests. Kubernetes continuously works to make **actual state** match desired state. If a pod crashes, Kubernetes automatically restarts it.

### 🔄 Rolling Updates
Deploy new versions without downtime. Kubernetes gradually replaces old pods with new
ones, governed by `maxSurge` and `maxUnavailable`. It does **not** roll back on its own —
a failed rollout stalls with the old version still serving, and you (or your CI) decide to
`kubectl rollout undo`. Notebook 02 breaks a rollout on purpose so you can see exactly
that.

### 🔒 Security in Depth
RBAC controls who can do what. NetworkPolicies control which pods can talk to which — as
long as your CNI enforces them. Pod Security Standards prevent containers from running as
root. And Kubernetes Secrets are **base64-encoded, not encrypted at rest by default**,
which is why Notebook 09 ends at external secret stores rather than at `kubectl create
secret`.

### 📊 Observability
Prometheus collects metrics, Grafana visualizes them, and alerting rules notify you before users notice problems.

### 🚀 GitOps
Your Git repository is the single source of truth. ArgoCD watches Git and automatically syncs changes to your cluster. Rollback = `git revert`.

## Prerequisites

### Tools

- **Docker Desktop** — [install](https://docs.docker.com/get-docker/) — must be *running*
- **minikube** — [install](https://minikube.sigs.k8s.io/docs/start/)
- **kubectl** — [install](https://kubernetes.io/docs/tasks/tools/)
- **Helm** — [install](https://helm.sh/docs/intro/install/) — needed from Notebook 04 on
- **git** — needed for Notebook 07
- Basic understanding of Docker containers and YAML

Every notebook opens with a preflight cell that checks for the binaries it needs and for
a reachable cluster, and stops with a clear message if anything is missing.

### Cluster resources — read this before Notebook 01

This is not a toy cluster. Across the series you install **kube-prometheus-stack**
(Notebook 05), **ArgoCD** (07) and **Istio** (08) into it, plus a sidecar on every pod.
Undersize the cluster and you do not get an error — you get pods stuck in `Pending` with
`insufficient cpu`, which is a much more confusing failure to debug.

| | Minimum | Recommended |
|---|---|---|
| minikube `--cpus` | 4 | 4 |
| minikube `--memory` | 6144 (6 GB) | 8192 (8 GB) |
| Docker Desktop allocation | 6 CPU / 8 GB | 6 CPU / 10 GB |
| Free disk | 20 GB | 40 GB |

Docker Desktop must be allocated *more* than minikube asks for, or minikube cannot start:
the minikube node is a container living inside Docker's allocation, so asking for
`--memory=8192` on an 8 GB Docker Desktop fails outright. **Notebook 01 therefore reads
Docker's own limit and computes the largest safe size** (floor 6144, ceiling 8192) instead
of hard-coding one. Raise Docker Desktop's memory in Settings → Resources if it reports
that it landed on the floor.

The three heavy installs are notebooks 05 (kube-prometheus-stack), 07 (ArgoCD) and 08
(Istio + a sidecar on every pod), and the series is arranged so that no two are resident at
once: **notebook 05 uninstalls the Prometheus stack in its own cleanup cell** (nothing
after it reads from Prometheus — notebook 10's HPA uses metrics-server, a separate
pipeline), notebook 07 deletes the `argocd` namespace in its, and notebook 08 frees the
monitoring namespace again before installing Istio in case you skipped notebook 05. Want
to keep Grafana? Comment out notebook 05's uninstall and set `FREE_MONITORING = False` at
the top of notebook 08 — then watch `docker stats minikube`.

> **The failure mode if you get this wrong is not a `Pending` pod.** With the docker
> driver on macOS and Windows, the kubelet reads the *host's* memory rather than the node
> container's cgroup limit, so a cluster started with `--memory=6144` reports ~7.6 GB of
> allocatable memory. The scheduler fills past the real ceiling, the kubelet never sees
> memory pressure and never evicts anything, and Docker stalls the whole node container
> instead — what you observe is the entire cluster disappearing with
> `Unable to connect to the server: net/http: TLS handshake timeout`. Notebook 01 warns
> you when the reported capacity does not match what minikube was given.

### Local images and your cluster (Notebook 02)

Notebook 02 builds the three sample services and then has to get them **into the
cluster's own image store**, which is not the same place as your laptop's Docker daemon:

| Cluster | How the image gets in |
|---|---|
| **minikube** | `docker build` on the host, then `minikube image load <tag>` |
| **kind** | `docker build`, then `kind load docker-image <tag>` |
| **Docker Desktop Kubernetes** | nothing — it shares the host daemon |

Notebook 02 detects which of these you are on, does the right thing, and then **verifies
the images are visible to the cluster** before deploying anything. Every manifest that
uses them also sets `imagePullPolicy: IfNotPresent`, because Kubernetes defaults the
policy to `Always` for any `:latest` tag — without it the kubelet ignores the local copy,
tries to pull `docker.io/k8s-lab/...`, and every pod sits in `ImagePullBackOff` while
`minikube image ls` shows the image is right there.

### Reaching the cluster from your laptop (Notebooks 03, 05, 07, 08)

On Linux you can `curl http://$(minikube ip):<nodePort>` directly. On **macOS and
Windows you cannot**: the Docker daemon runs inside its own VM and the node's IP is on a
network the host cannot route to, so the request times out with no useful error.
`minikube service <name> --url` works but *blocks*, holding a tunnel open — which hangs a
notebook cell forever. Every notebook here uses `kubectl port-forward` instead, which
behaves identically on every platform, and picks a free local port rather than assuming
9090/3000 are available.

### NetworkPolicy enforcement (Notebook 06)

A NetworkPolicy is enforced by the **CNI plugin**, not by Kubernetes. minikube's default
CNI does not enforce it: the objects are created, `kubectl get networkpolicy` lists them,
and nothing is blocked. If you want Notebook 06's security demos to really block traffic,
start the cluster with Calico:

```bash
minikube start --cpus=4 --memory=6144 --driver=docker --cni=calico
```

Notebook 06 detects which CNI you have and tells you what to expect either way, so it is
safe to start without Calico and decide later. (Switching means `minikube delete` and
re-running Notebooks 01–03.)

## Quick Start

```bash
# Navigate to the lab directory
cd 03-technologies/container-orchestration/kubernetes

# Install Python dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

# Start minikube (Notebook 01 does this for you, sized to your Docker allocation)
minikube start --cpus=4 --memory=6144 --driver=docker

# Open notebooks/01_cluster_setup.ipynb and start learning!
```

Notebooks write their generated YAML next to themselves in `notebooks/` and clean it up in
their own cleanup cells. Every notebook is safe to re-run from the top.

## Project Structure

```
kubernetes/
├── README.md              # This file
├── pyproject.toml          # Python dependencies
├── notebooks/              # Jupyter notebooks (the labs)
│   #   notebooks also generate scratch YAML here and delete it in cleanup
│   ├── 01_cluster_setup.ipynb
│   ├── 02_pods_and_deployments.ipynb
│   ├── 03_services_and_networking.ipynb
│   ├── 04_helm_and_kustomize.ipynb
│   ├── 05_observability.ipynb
│   ├── 06_rbac_and_security.ipynb
│   ├── 07_gitops_with_argocd.ipynb
│   ├── 08_service_mesh.ipynb
│   ├── 09_storage_and_secrets.ipynb
│   └── 10_production_patterns.ipynb
├── manifests/              # K8s YAML manifests used in labs
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── rbac.yaml
│   ├── networkpolicy.yaml
│   ├── hpa.yaml
│   ├── prometheus-values.yaml
│   └── argocd-app.yaml
└── apps/                   # Sample microservices
    ├── api-gateway/
    ├── user-service/
    └── order-service/
```

## Stopping the Lab

```bash
minikube stop          # Stop the cluster (preserves data)
minikube delete        # Delete the cluster entirely
```

## License

Educational content — feel free to use and modify for learning purposes.
