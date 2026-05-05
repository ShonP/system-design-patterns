# Lab 06 — Kubernetes Security

## 🎯 What you'll learn

- Scan **Kubernetes manifests** statically with Kubescape and Trivy
- Audit a running cluster against the **CIS Kubernetes Benchmark** with kube-bench
- Apply **Pod Security Standards** (`restricted`, `baseline`, `privileged`) and watch admission reject bad pods
- Write **NetworkPolicies** to default-deny pod-to-pod traffic and allowlist the few flows you actually need
- Tighten **RBAC** — diff a "developer" role with too many verbs vs the least-privilege version
- Install **Trivy Operator** for continuous in-cluster scanning

## 📋 Prerequisites

- Docker
- ~3 GB free disk + 2 GB RAM for `kind` (Kubernetes-in-Docker)
- `kubectl` (`brew install kubectl` or follow [kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/))
- `helm` (for trivy-operator install) — `brew install helm`

## 🔧 Setup

```bash
$ cd 06-kubernetes-security
$ ./scripts/kind-up.sh           # creates a 3-node kind cluster called "seclabs"
$ kubectl get nodes              # confirm
$ ./scripts/run-kubescape.sh --version
```

When done:

```bash
$ ./scripts/kind-down.sh         # destroys the cluster
```

---

## 📝 Exercises

### Exercise 1 — Static scan of bad manifests with Kubescape

```bash
$ ./scripts/run-kubescape.sh scan framework nsa manifests/bad/ --format json --output exercises/kubescape.json
$ ./scripts/run-kubescape.sh scan framework nsa manifests/bad/
```

> ✅ Expected: dozens of failed controls — `runAsNonRoot: false`, `privileged: true`, `hostNetwork: true`, missing resource limits, world-readable secrets, etc.

### Exercise 2 — Static scan with Trivy (config / k8s)

```bash
$ ./scripts/run-trivy.sh config manifests/bad/
$ ./scripts/run-trivy.sh config --severity HIGH,CRITICAL --format json --output exercises/trivy-config.json manifests/bad/
```

Compare what Kubescape flags vs Trivy. They overlap heavily but use different rule packs (NSA / MITRE / CIS for Kubescape; Trivy uses Defsec/Misconfig).

### Exercise 3 — Apply the BAD manifests and watch them succeed

In a permissive default cluster, this works (and that's the point):

```bash
$ kubectl create namespace bad
$ kubectl apply -f manifests/bad/ -n bad
$ kubectl get pod -n bad
$ kubectl exec -n bad deploy/web -- id     # root :(
```

Now turn on Pod Security admission — `restricted` enforcement at the namespace level:

```bash
$ kubectl label namespace bad \
    pod-security.kubernetes.io/enforce=restricted \
    pod-security.kubernetes.io/enforce-version=latest --overwrite
$ kubectl rollout restart deploy/web -n bad
$ kubectl describe pod -n bad -l app=web | grep -A5 Events
```

> ✅ Expected: pods now **fail to schedule** with a Pod Security admission denial. The platform protected you from yourself.

### Exercise 4 — Apply the GOOD manifests under `restricted`

```bash
$ kubectl create namespace good
$ kubectl label namespace good \
    pod-security.kubernetes.io/enforce=restricted \
    pod-security.kubernetes.io/enforce-version=latest
$ kubectl apply -f manifests/good/ -n good
$ kubectl get pod -n good
$ kubectl exec -n good deploy/web -- id    # uid=10001(app)
```

Diff `manifests/bad/web.yaml` vs `manifests/good/web.yaml` — every line is a hardening lesson.

### Exercise 5 — Default-deny NetworkPolicy

`kind` ships with no CNI policy enforcement by default. Install Calico:

```bash
$ ./scripts/install-calico.sh
$ kubectl apply -f manifests/networkpolicies/default-deny.yaml -n good
$ kubectl run tmp --rm -it --image=alpine -n good -- sh -c "wget -qO- web.good.svc:80 || echo BLOCKED"
BLOCKED
$ kubectl apply -f manifests/networkpolicies/allow-frontend.yaml -n good
$ kubectl run tmp --rm -it --image=alpine -n good -l app=frontend -- sh -c "wget -qO- web.good.svc:80"
```

> 💡 Default-deny NetworkPolicies are the single highest-leverage k8s control. Every namespace should have one.

### Exercise 6 — RBAC: too-many-verbs developer role

Look at `manifests/rbac/dev-role-bad.yaml`:

```yaml
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs:     ["*"]
```

Apply it, impersonate the user, and notice you can do *anything*:

```bash
$ kubectl apply -f manifests/rbac/dev-role-bad.yaml
$ kubectl auth can-i delete nodes --as=jane@example.com    # yes (oof)
```

Now apply the good role and re-check:

```bash
$ kubectl delete -f manifests/rbac/dev-role-bad.yaml
$ kubectl apply -f manifests/rbac/dev-role-good.yaml
$ kubectl auth can-i delete nodes --as=jane@example.com    # no
$ kubectl auth can-i list pods --as=jane@example.com -n good  # yes
```

### Exercise 7 — kube-bench (CIS Kubernetes Benchmark)

```bash
$ ./scripts/run-kube-bench.sh
```

Read the output. On a `kind` cluster you'll see lots of `[WARN]` for control plane components — `kind` is not configured for production. **The point is to see the format and the controls.** When you run this on a real cluster, treat each `[FAIL]` as a ticket.

### Exercise 8 — Trivy Operator (continuous scanning)

```bash
$ ./scripts/install-trivy-operator.sh
$ kubectl get pods -n trivy-system
$ # Wait ~30s for first scan
$ kubectl get vulnerabilityreports -A
$ kubectl get configauditreports -A
```

These are CRDs you can query, RBAC, dashboard against, ship to Prometheus, etc. **Continuous** is the keyword — every time someone deploys, you get a fresh scan.

```bash
$ kubectl get vulnerabilityreports -n bad -o json \
   | jq -r '.items[].report.summary | "\(.criticalCount) crit / \(.highCount) high"'
```

---

## 💡 Key Concepts

| Concept                           | TL;DR                                                                                                   |
|-----------------------------------|---------------------------------------------------------------------------------------------------------|
| **Pod Security Standards (PSS)**  | `privileged` / `baseline` / `restricted`. Set per namespace as label. Replaces deprecated PodSecurityPolicy. |
| **NetworkPolicy**                 | k8s-native firewall: who can talk to whom. CNI must support enforcement (Calico, Cilium, Antrea, …).    |
| **RBAC**                          | Role/ClusterRole + RoleBinding. Always least-privilege; never `verbs: ["*"]` outside `cluster-admin`.    |
| **Admission Controllers**         | Kyverno / OPA Gatekeeper add custom policy beyond PSS. Worth adopting for any non-trivial cluster.       |
| **Trivy Operator**                | DaemonSet+CRDs for continuous scanning. Reads images, configs, RBAC, secrets.                            |
| **Kubescape frameworks**          | NSA / MITRE / ArmoBest / CIS bundles of controls. Pick one and tune.                                     |
| **CIS Benchmark**                 | Rough audit of *the cluster itself* (kubelet flags, etcd encryption, …). Use `kube-bench`.               |
| **Workload identity**             | Pods get cloud IAM via `IAM Roles for Service Accounts` / Workload Identity Federation, not static keys. |

### The cluster threat surface

```text
                     ┌──────────────┐
   bad image ──────► │  Container   │ ───────► RCE in the container
                     └──────┬───────┘
                            │  no PSS  → root, capabilities
                            ▼
                     ┌──────────────┐
   bad pod spec ───► │   Pod        │ ───────► escape to node
                     └──────┬───────┘
                            │  no NetworkPolicy → lateral movement
                            ▼
                     ┌──────────────┐
   bad RBAC ───────► │  ServiceAcct │ ───────► API server takeover
                     └──────┬───────┘
                            │  no encryption at rest, no audit
                            ▼
                     ┌──────────────┐
                     │   Cluster    │
                     └──────────────┘
```

PSS, NetworkPolicy, RBAC and image scanning each cut one of these arrows.

---

## 🏆 Challenge

1. **Kyverno policy.** Install Kyverno and write a ClusterPolicy that **mutates** every pod to add a default `securityContext.runAsNonRoot: true`. Demonstrate it on the `bad/` manifests.
2. **NetworkPolicy from observation.** Use `kubectl exec` to map the actual traffic between pods in the `good` namespace, then write the **minimal** NetworkPolicy set that allows only those flows.
3. **Audit-only first, enforce later.** Configure PSS in `audit` mode for one namespace, generate violations, then graduate to `enforce`. Document what you would do at each step in a real org rollout.
4. **GitOps the lot.** Commit `manifests/good/` to a separate repo, apply it via [Argo CD](https://github.com/argoproj/argo-cd) or [Flux](https://github.com/fluxcd/flux2), and gate it on Trivy Operator passing. Doc the failure UX when a CVE breaks the pipeline.

---

## 📚 Further reading

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubescape](https://github.com/kubescape/kubescape) — also runs as an in-cluster operator
- [Trivy Operator docs](https://aquasecurity.github.io/trivy-operator/)
- [kube-bench](https://github.com/aquasecurity/kube-bench)
- [Kyverno](https://kyverno.io/) and [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper)
- [NSA/CISA Kubernetes Hardening Guidance](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
- `research-report.md` §4.4 in this repo

➡️ Next: [Lab 07 — Infrastructure as Code](../07-infrastructure-as-code/)
