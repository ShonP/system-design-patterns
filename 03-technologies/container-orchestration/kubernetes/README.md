# Kubernetes Enterprise Platform

📖 **What you'll learn**: How to build, deploy, secure, and operate a production-grade Kubernetes platform — from your first cluster to GitOps, service mesh, observability, and production hardening.

## The Problem

You need to run microservices in production. You need them to:

1. **Scale automatically** when traffic spikes
2. **Self-heal** when containers crash
3. **Roll out updates** without downtime
4. **Isolate teams** so one team can't break another's services
5. **Observe everything** — metrics, logs, traces
6. **Stay secure** — RBAC, network policies, encrypted secrets

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

| # | Notebook | What You'll Learn | Time |
|---|----------|-------------------|------|
| 1 | Cluster Setup | Install minikube, kubectl, create cluster, explore with kubectl | 30 min |
| 2 | Pods & Deployments | Create pods, deployments, rolling updates, scaling | 45 min |
| 3 | Services & Networking | ClusterIP, NodePort, LoadBalancer, Ingress with NGINX | 45 min |
| 4 | Helm & Kustomize | Package apps with Helm, overlay configs with Kustomize | 45 min |
| 5 | Observability | Prometheus + Grafana stack, metrics, dashboards | 60 min |
| 6 | RBAC & Security | Namespaces, RBAC, NetworkPolicies, Pod Security Standards | 45 min |
| 7 | GitOps with ArgoCD | Install ArgoCD, deploy via Git, auto-sync, self-heal | 45 min |
| 8 | Service Mesh | Install Istio, traffic splitting, mTLS, observability | 60 min |
| 9 | Storage & Secrets | PV/PVC, ConfigMaps, Secrets, External Secrets pattern | 45 min |
| 10 | Production Patterns | HPA/VPA, resource limits, multi-tenancy, Velero backup | 60 min |

**Total estimated time: ~8 hours**

## Key Concepts Covered

### 🏗️ Container Orchestration
Kubernetes manages the lifecycle of your containers — scheduling, scaling, healing, and networking — so you don't have to.

### 📦 Declarative Configuration
You describe your **desired state** in YAML manifests. Kubernetes continuously works to make **actual state** match desired state. If a pod crashes, Kubernetes automatically restarts it.

### 🔄 Rolling Updates
Deploy new versions without downtime. Kubernetes gradually replaces old pods with new ones, and automatically rolls back if health checks fail.

### 🔒 Security in Depth
RBAC controls who can do what. NetworkPolicies control which pods can talk to which. Pod Security Standards prevent containers from running as root.

### 📊 Observability
Prometheus collects metrics, Grafana visualizes them, and alerting rules notify you before users notice problems.

### 🚀 GitOps
Your Git repository is the single source of truth. ArgoCD watches Git and automatically syncs changes to your cluster. Rollback = `git revert`.

## Prerequisites

- **Docker Desktop** — [install](https://docs.docker.com/get-docker/)
- **minikube** — [install](https://minikube.sigs.k8s.io/docs/start/)
- **kubectl** — [install](https://kubernetes.io/docs/tasks/tools/)
- **Helm** — [install](https://helm.sh/docs/intro/install/)
- Basic understanding of Docker containers
- Basic understanding of YAML

## Quick Start

```bash
# Navigate to the lab directory
cd 03-technologies/container-orchestration/kubernetes

# Install Python dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=k8s-lab --display-name="K8s Lab (Python)"

# Start minikube (done in Notebook 01)
minikube start --cpus=4 --memory=8192 --driver=docker

# Open the first notebook and start learning!
```

## Project Structure

```
kubernetes/
├── README.md              # This file
├── pyproject.toml          # Python dependencies
├── notebooks/              # Jupyter notebooks (the labs)
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
