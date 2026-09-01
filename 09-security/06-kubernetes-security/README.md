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
- ~3 GB free disk + 2 GB RAM for `kind` (Kubernetes-in-Docker). Measured 2026-08-24: the
  three node containers peaked at **1.3 GB** with Trivy Operator and every exercise's
  workloads running.
- `kind` — `brew install kind` (or [kind.sigs.k8s.io](https://kind.sigs.k8s.io/))
- `kubectl` (`brew install kubectl` or follow [kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/))
- `helm` (for trivy-operator install) — `brew install helm`

Everything else — Kubescape, Trivy, kube-bench — runs from a container, so there is
nothing else to install.

> 📌 **Every number in this file was measured**, on 2026-08-24, with kind v0.32.0 /
> `kindest/node:v1.36.1` (Kubernetes 1.36.1), Kubescape v3.0.22, Trivy 0.74.0,
> kube-bench v0.10.4 and the trivy-operator chart 0.35.0. Scanner rule packs and CVE feeds
> drift; treat the counts as the *shape* of the answer and re-measure if yours differ by
> more than a few. `scripts/kind-up.sh` pins the node image for exactly that reason.

## 🔧 Setup

```bash
$ cd 06-kubernetes-security
$ ./scripts/kind-up.sh           # creates a 3-node kind cluster called "seclabs"
$ kubectl config current-context # kind-seclabs -- kind-up.sh sets it explicitly
$ kubectl get nodes              # confirm: 3x Ready
$ ./scripts/run-kubescape.sh version
```

> ⚠️ Every command below runs against your **current context**, and this lab deliberately
> deploys privileged, root, host-network pods. `kind-up.sh` calls
> `kubectl config use-context kind-seclabs` so that context is `seclabs` and not whatever
> you were last pointed at. If you switch contexts mid-lab, switch back before applying
> anything from `manifests/bad/`.

> ℹ️ **Exercise 5 and the CNI.** For most of kind's history the default CNI (kindnet)
> accepted NetworkPolicy objects and enforced nothing — the policy applies cleanly,
> `kubectl get netpol` lists it, and every packet still flows. That is no longer true:
> on `kindest/node:v1.36.1` **kindnet enforces**, verified 2026-08-24 both by Service name
> and by pod IP (so it is real L3/L4 filtering, not just DNS breaking). The whole of
> exercise 5 therefore runs on the cluster you just created. Exercise 5 still starts by
> *proving* enforcement instead of assuming it, and keeps the Calico rebuild as the
> fallback for when yours turns out not to enforce.

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

> ✅ Expected: **12 of the NSA framework's 20 controls fail, compliance score 40%**
> (measured 2026-08-24, Kubescape v3.0.22). Six High — `Privileged container`,
> `Host PID/IPC privileges`, `HostNetwork access`, `Applications credentials in
> configuration files`, `Ensure CPU limits are set`, `Ensure memory limits are set`; five
> Medium — `Non-root containers`, `Allow privilege escalation`, `Ingress and Egress
> blocked`, `Automatic mapping of service account`, `Linux hardening`; one Low —
> `Immutable container filesystem`.

Two things the table does *not* say, which matter more than the ones it does:

- **Only the Deployment is scanned.** `Resource Summary` reads `1 / 1`: Kubescape's NSA
  controls target workloads, so the `Service` and the `Secret` in the same directory are
  never evaluated. A directory scan is not a directory-wide audit.
- **`image: nginx:latest` is not flagged.** There is no mutable-tag control in the NSA
  bundle at all — the console table only lists failures, so print the full set of 20 from
  the JSON you just wrote:
  `jq -r '.summaryDetails.controls | to_entries[] | "\(.value.statusInfo.status)\t\(.value.name)"' exercises/kubescape.json | sort`
  Trivy catches the image issues in exercise 2; this is the practical argument for running
  two scanners rather than one. While you have that list open, note the control named
  **`PSP enabled`**, sitting there `passed`. PodSecurityPolicy has not existed since
  Kubernetes 1.25 (see Key Concepts). A `passed` from a rule that cannot fail is not the
  same thing as a control being in place — rule packs go stale, and yours will too.

Kubescape scores each control by *impact × how many resources fail it*. Read the score, then
ignore it: a compliance percentage is a management artifact. The four findings that decide
whether a container breakout ends at the pod boundary are `privileged`, `hostPID`,
`hostNetwork` and running as uid 0 — everything else on that list is a distant second.

### Exercise 2 — Static scan with Trivy (config / k8s)

```bash
$ ./scripts/run-trivy.sh config manifests/bad/
$ ./scripts/run-trivy.sh config --severity HIGH,CRITICAL --format json --output exercises/trivy-config.json manifests/bad/
```

> ✅ Expected: `Tests: 121 (SUCCESSES: 99, FAILURES: 22)` /
> `Failures: 22 (UNKNOWN: 0, LOW: 12, MEDIUM: 5, HIGH: 5, CRITICAL: 0)`
> (measured 2026-08-24, Trivy 0.74.0). The second command filters to the five HIGHs, which
> are the ones worth waking up for: `KSV-0009` host network, `KSV-0010` host PID,
> `KSV-0014` root filesystem not read-only, `KSV-0017` privileged, `KSV-0118` default
> security context.

Compare what Kubescape flags vs Trivy. They overlap heavily but use different rule packs
(NSA / MITRE / CIS for Kubescape; Trivy uses Defsec/Misconfig), and they disagree about
volume rather than about the verdict: 12 controls vs 22 checks, the same four real
problems at the top. The interesting difference is at the edges — Trivy raises
`KSV-0013 Image tag ":latest" used`, which the NSA bundle has no control for, and splits
things Kubescape merges (CPU limit and CPU request are two findings here, one there).
Neither tool looks at the `Secret`.

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
```

Both commands already tell you something. Labelling the namespace prints a `Warning` for
every *existing* pod that violates the new level (PSA evaluates them but never evicts
them), and `rollout restart` prints a second `Warning: would violate PodSecurity` — that
one comes from PSA checking the **Deployment's** pod template, which is a warning and not
a rejection, because Deployments are not pods.

The rejection itself happens further down. Look at what actually exists now:

```bash
$ kubectl get pods -n bad
NAME                   READY   STATUS    RESTARTS   AGE
web-6fc787875b-9khjm   1/1     Running   0          41s        # still the OLD pod
$ kubectl -n bad get rs
NAME             DESIRED   CURRENT   READY   AGE
web-5799d979bc   1         0         0       22s               # new RS: wants 1, has 0
web-6fc787875b   1         1         1       48s
```

**The old pod does not go away.** A rolling update with one replica surges *before* it
scales down, the new pod is rejected, so the rollout wedges and the old, privileged pod
keeps serving. That is worth sitting with: turning on `restricted` did not evict anything.
It stopped the *next* deploy. PSA is an admission control, and admission only ever sees
new objects.

There is no rejected pod to describe — the object was never persisted — so the error lands
on the controller that tried to create it:

```bash
$ kubectl -n bad get events --field-selector reason=FailedCreate \
    -o custom-columns=MESSAGE:.message --no-headers | tail -1
```

> ✅ Expected: `Error creating: pods "web-5799d979bc-..." is forbidden: violates
> PodSecurity "restricted:latest": host namespaces (hostNetwork=true, hostPID=true),
> hostPort (container "web" uses hostPort 80), privileged (container "web" must not set
> securityContext.privileged=true), allowPrivilegeEscalation != false, unrestricted
> capabilities, runAsNonRoot != true, runAsUser=0, seccompProfile`

Note `hostPort 80`, which the manifest never sets: with `hostNetwork: true` every
`containerPort` *is* a host port, and `restricted` counts it as one.

`kubectl describe replicaset -l app=web` is a tempting shortcut here and a trap — describing
a *selection* of objects drops the Events section, so you get two pod templates and no
error. Describe the new ReplicaSet by name (`kubectl -n bad describe rs web-5799d979bc`)
or read the events as above.

Delete the survivor and the namespace really does go empty:

```bash
$ kubectl -n bad delete pod -l app=web
$ kubectl get pods -n bad
No resources found in bad namespace.
```

Two things to take from all this:

- It is **admission**, not scheduling. The pod object is never persisted; the scheduler
  never sees it. That is why `kubectl get pods` ends up empty rather than showing
  `Pending`.
- PSA is **namespace-scoped and label-driven**, which means anyone who can edit a namespace
  label can turn it off. It is a guardrail, not a boundary. `warn` and `audit` labels give
  you the same evaluation without blocking — that is how you roll it out to an existing
  namespace without an outage (challenge 3).

### Exercise 4 — Apply the GOOD manifests under `restricted`

```bash
$ kubectl create namespace good
$ kubectl label namespace good \
    pod-security.kubernetes.io/enforce=restricted \
    pod-security.kubernetes.io/enforce-version=latest
$ kubectl apply -f manifests/good/ -n good
$ kubectl get pod -n good
$ kubectl exec -n good deploy/web -- id    # uid=10001 gid=10001 groups=10001
```

> ℹ️ The id has no name attached: `runAsUser: 10001` sets a numeric uid that has no
> `/etc/passwd` entry in the image. That is normal and correct for `restricted` workloads —
> and it is why the image has to be one that works as an arbitrary uid
> (`nginxinc/nginx-unprivileged`, not `nginx`, which needs root to bind :80 and to write
> its pid file).

> 💡 `readOnlyRootFilesystem: true` is the line in `manifests/good/web.yaml` most likely to
> bite you when you copy it to your own workload. Every path the process writes to needs a
> volume, and you find them one CrashLoopBackOff at a time:
> `[emerg] mkdir() "/tmp/proxy_temp" failed (30: Read-only file system)`. nginx-unprivileged
> needs three — `/var/cache/nginx`, `/var/run` and `/tmp` — and `/tmp` is the one everybody
> forgets, because "nginx writes to /tmp" is not in anyone's mental model of nginx.

Diff `manifests/bad/web.yaml` vs `manifests/good/web.yaml` — every line is a hardening
lesson. The five that `restricted` actually requires:
`runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `capabilities.drop: ["ALL"]`,
`seccompProfile.type: RuntimeDefault`, and no host namespaces / privileged / hostPath.

Now close the loop the same way you would in CI — rescan the *fixed* manifests:

```bash
$ ./scripts/run-kubescape.sh scan framework nsa manifests/good/
$ ./scripts/run-trivy.sh config manifests/good/
```

> ✅ Expected (measured 2026-08-24):
>
> | scan | `manifests/bad/` | `manifests/good/` |
> |---|---|---|
> | Kubescape NSA | 12 failed / 20 controls, score 40% | **1 failed / 20, score 95%** |
> | Trivy config  | 22 failures (5 HIGH, 5 MED, 12 LOW) | **2 failures (0 HIGH, 1 MED, 1 LOW)** |
>
> Every High is gone. What is left is exactly three checks, and each one is a different
> kind of "finding":
>
> - Kubescape `Ingress and Egress blocked` (Medium) — there is no NetworkPolicy in this
>   directory. A **real gap, fixed in exercise 5**, in a different file.
> - Trivy `KSV-0125 Restrict container images to trusted registries` (Medium) — Docker Hub
>   is not your registry. A **real control that this lab cannot satisfy**; in your org it
>   is satisfied by mirroring into your own registry, not by editing the manifest.
> - Trivy `KSV-0110 Workloads in the default namespace` (Low) — an artefact of scanning a
>   file that has no `metadata.namespace`, when in fact you deploy it with `-n good`.
>   **Noise.** Static scanning cannot see the `-n` you are going to type.
>
> That last one is the reason a compliance percentage is not a target. Getting from 95% to
> 100% here means annotating a file to satisfy a scanner about a namespace you already set
> correctly.

### Exercise 5 — Default-deny NetworkPolicy

> ⚠️ If your CNI turns out not to enforce, the fix below **destroys and recreates the
> cluster**, which takes the `bad` namespace with it. Exercise 5b is two `kubectl get`s
> against that namespace — do it first if you want to keep the option open.

A NetworkPolicy is an *object*; enforcement is the CNI's job. If the CNI ignores them,
everything looks applied and nothing is blocked — the most misleading failure mode in
Kubernetes networking. So the exercise starts by proving the network is open, then closes
it, then proves it closed. Never skip the first step: a broken policy and a broken app
produce identical symptoms.

Deploy the workload if you have not already (exercise 4 did this):

```bash
$ kubectl create namespace good
$ kubectl label namespace good pod-security.kubernetes.io/enforce=restricted
$ kubectl apply -f manifests/good/ -n good
$ kubectl wait --for=condition=available deploy/web -n good --timeout=120s
```

The probe is `scripts/probe.sh`. It starts a one-shot alpine pod, fetches `web.good.svc:80`
and prints `ALLOWED` or `BLOCKED`:

```bash
$ ./scripts/probe.sh              # a pod with no labels
ALLOWED
$ ./scripts/probe.sh app=frontend # a pod labelled app=frontend
ALLOWED
```

> ℹ️ **Why a script and not `kubectl run --image=alpine`.** The `good` namespace enforces
> Pod Security `restricted`, and a default `kubectl run` pod violates it — root, no seccomp
> profile, capabilities not dropped. It is rejected at admission, never starts, and never
> sends a packet. The shell sees a non-zero exit and a `--` chain like
> `... && echo ALLOWED || echo BLOCKED` happily prints `BLOCKED`. You would then "prove"
> your NetworkPolicy works on a cluster where it does nothing at all. `probe.sh` passes the
> `--overrides` that `restricted` requires — read it, it is short, and the override block
> is the smallest pod spec `restricted` will accept.

Now deny everything:

```bash
$ kubectl apply -f manifests/networkpolicies/default-deny.yaml -n good
$ ./scripts/probe.sh
BLOCKED
```

> ✅ If that still says `ALLOWED`, **your CNI is not enforcing NetworkPolicy** and nothing
> in the rest of this exercise means anything. Jump to "If your CNI does not enforce" below.
> Measured 2026-08-24: kindnet on `kindest/node:v1.36.1` **does** enforce, and so does
> Calico v3.28.2 — both were verified for this exercise.

`BLOCKED` has two causes stacked on top of each other, and it is worth separating them,
because in a real outage you will need to know which one you are looking at. The probe
resolves `web.good.svc` before it connects, and default-deny blocks egress to CoreDNS
(which lives in another namespace) just as thoroughly as it blocks egress to `web`. Take
DNS out of the picture by targeting the pod IP directly:

```bash
$ IP=$(kubectl get pod -n good -l app=web -o jsonpath='{.items[0].status.podIP}')
$ TARGET="$IP:8080" ./scripts/probe.sh
BLOCKED
```

Still blocked, so the connection itself is being dropped — not merely name resolution.
(Delete the policy and re-run that same command: `ALLOWED`. That two-command pair is the
cleanest proof of enforcement there is, because it removes DNS as an explanation.)

Then allow exactly one flow:

```bash
$ kubectl apply -f manifests/networkpolicies/allow-frontend.yaml -n good
$ ./scripts/probe.sh app=frontend
ALLOWED
$ ./scripts/probe.sh
BLOCKED
```

> The second pod has no `app=frontend` label, so it is still denied. That difference —
> same namespace, same image, different label — is the whole model: **NetworkPolicy is
> identity-based (labels), not address-based**, which is what makes it survive pod IPs
> changing every restart.

Read `manifests/networkpolicies/allow-frontend.yaml`: it takes **three** policies to let
one pod reach one Service. Egress from the client, ingress to the server, and egress to
CoreDNS for everybody. Forgetting the third is the single most common default-deny outage.

#### If your CNI does not enforce

You cannot add Calico on top of kindnet — the cluster has to be created without a CNI:

```bash
$ ./scripts/kind-down.sh
$ CNI=calico ./scripts/kind-up.sh      # nodes stay NotReady until the CNI is installed
$ ./scripts/install-calico.sh
$ kubectl get nodes                    # all Ready again
```

Then recreate the workload (the cluster is new) and rerun the sequence above from the top.
`install-calico.sh` refuses to run if it finds the kindnet DaemonSet, because two CNIs on
one cluster is unpredictable networking rather than a NetworkPolicy lab.

> 💡 Default-deny NetworkPolicies are the single highest-leverage k8s control. Every
> namespace should have one. Two caveats worth internalising:
> **(1)** They are enforced by the CNI, not by Kubernetes. On a CNI that ignores them —
> old kindnet, and some managed clusters until you enable the feature — every policy in
> this exercise is a no-op that reports success. Always test with a pod, never by reading
> `kubectl get netpol`.
> **(2)** They are **L3/L4 only**. `allow frontend -> web:8080` permits any TCP traffic on
> that port, including an attacker who has compromised the frontend. Service-mesh mTLS or
> an L7 policy engine (Cilium, Istio AuthorizationPolicy) is what adds "and only GET /api".

### Exercise 5b — Secrets are base64, not encryption

> ℹ️ Needs the `bad` namespace from exercise 3. If you rebuilt the cluster for Calico in
> exercise 5, recreate it first: `kubectl create ns bad && kubectl apply -f manifests/bad/ -n bad`
> (the Secret applies even when the Deployment's pods are rejected).

The bad manifests included a Secret. Read it back:

```bash
$ kubectl -n bad get secret leaky-secret -o jsonpath='{.data.password}'
aHVudGVyMg==
$ kubectl -n bad get secret leaky-secret -o jsonpath='{.data.password}' | base64 -d
hunter2
```

> ⚠️ **`kind: Secret` is not encrypted. It is base64, which is an encoding, not a cipher.**
> The only things a Secret gives you over a ConfigMap are: it is not printed by default in
> `kubectl describe`, it can be RBAC-restricted separately, and it *may* be encrypted at
> rest if the cluster operator configured that. On a stock cluster it is stored in etcd in
> plaintext.

Which means the real controls are elsewhere:

| Control | What it stops | Where |
|---|---|---|
| `EncryptionConfiguration` on the API server (AES-GCM or a KMS provider) | Someone reading etcd's disk or a snapshot | Cluster config — **off by default** |
| RBAC: nobody gets `get`/`list` on `secrets` in a namespace they don't own | Any pod/user reading every credential in the namespace | `Role`, exercise 6 |
| `automountServiceAccountToken: false` | A compromised pod using its SA token to read Secrets via the API | `manifests/good/web.yaml` — already set |
| External secret stores (Vault, ESO, cloud secret managers) with short-lived leases | The whole class: credentials that live forever in a cluster object | Outside Kubernetes |
| Don't put secrets in `env` at all | `kubectl describe pod` / crash dumps / logs leaking them | `manifests/bad/web.yaml` does exactly this |

Check whether your own cluster encrypts at rest — on kind, it does not:

```bash
$ kubectl -n kube-system get pod -l component=kube-apiserver \
    -o jsonpath='{.items[0].spec.containers[0].command}' | tr ',' '\n' | grep -i encryption
# (no output = no --encryption-provider-config = plaintext in etcd)
```

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

> ℹ️ `kubectl` prints `Warning: resource 'nodes' is not namespace scoped` before each
> answer, because `can-i` defaults to a namespace and `nodes` is cluster-scoped. It is
> noise, not a failure — the `yes`/`no` below it is the answer. `dev-role-good.yaml` is a
> namespaced `Role` in `good`, which is why the same user loses `nodes` entirely and keeps
> read access to one namespace.

### Exercise 7 — kube-bench (CIS Kubernetes Benchmark)

```bash
$ ./scripts/run-kube-bench.sh
```

This applies `manifests/kube-bench-job.yaml` — a Job pinned to the control-plane node — and
prints its logs. **It has to run on the node it is auditing**: kube-bench reads
`/etc/kubernetes/manifests/*.yaml`, kubelet config and file permissions from the host it
runs on. Running the container on your laptop (the previous version of this script did)
audits your laptop's `/etc`, which on kind is not the control plane at all — the control
plane is inside a Docker container. You get a report full of confident, meaningless results.

> ✅ Expected (measured 2026-08-24, kube-bench v0.10.4 against Kubernetes 1.36.1):
>
> ```
> == Summary master ==    38 PASS   9 FAIL  12 WARN
> == Summary etcd ==       7 PASS   0 FAIL   0 WARN
> == Summary policies ==   0 PASS   6 FAIL  29 WARN
> == Summary total ==     45 PASS  15 FAIL  41 WARN
> ```

**Read that score with a lot of suspicion.** Four things are wrong with it, and knowing
which is which is more valuable than the number:

1. **The benchmark does not match the cluster.** kube-bench auto-detects your Kubernetes
   version and picks the closest CIS benchmark it ships. Here it detected `1.36` and
   selected **`cis-1.10`** — the newest it has. Controls are being checked against a
   benchmark written for an older Kubernetes. That is the right behaviour (better than
   hard-coding `cis-1.24`, which the previous version of this job did) but it is not an
   exact audit. Check what yours picked — add `--json` to the Job's command and read the
   first object: `{"id":"1","version":"cis-1.10","detected_version":"1.36",...}`.
2. **A kind "node" is a container.** kube-bench audits file permissions, ownership and
   process flags on the host it runs on. On kind that host is a Docker container sharing
   your laptop's kernel, with no real etcd user, no systemd kubelet unit, and a control
   plane that was never installed the way the benchmark assumes. `[FAIL] 1.1.12 Ensure
   that the etcd data directory ownership is set to etcd:etcd` is *true* and *irrelevant*:
   there is no etcd user in the image.
3. **The `policies` section scores 0 PASS by construction.** 29 of its 35 checks are
   `(Manual)` — kube-bench prints the remediation text and marks `[WARN]` without checking
   anything. The 6 that do fail are all generic RBAC hygiene — `5.1.1 cluster-admin role`,
   `5.1.2 minimize access to secrets`, `5.1.3 wildcard use in Roles`, `5.1.4 access to
   create pods`, `5.1.5 default service accounts`, `5.1.6 SA tokens mounted` — and every
   one of them is triggered by the built-in system roles that ship with Kubernetes. They
   are prompts to go and look, not defects this cluster introduced.
4. **The node section is not audited at all.** This Job runs `--targets master,etcd,policies`
   because it is pinned to the control-plane node. Section 4 (kubelet configuration) —
   arguably the half that matters most for workload security — is simply absent from the
   totals.

So: **the point is to see the format and the controls, not the score.** On a real
self-managed cluster, treat each `[FAIL]` as a ticket. On EKS/GKE/AKS most of the
control-plane section is not yours to fix (use `--targets node,policies` there, and the
provider's own benchmark). On kind, treat the whole thing as a worked example.

### Exercise 8 — Trivy Operator (continuous scanning)

```bash
$ ./scripts/install-trivy-operator.sh
$ kubectl get pods -n trivy-system
$ # ConfigAuditReports appear in seconds; VulnerabilityReports need a scan Job per
$ # workload, so give it 2-3 minutes on a fresh cluster (every image is pulled once).
$ kubectl get vulnerabilityreports -A
$ kubectl get configauditreports -A
```

> ⚠️ **Version-match the operator to your cluster.** `install-trivy-operator.sh` pins chart
> **0.35.0** (app 0.33.0). Chart 0.24.1 — which this lab used to pin — *installs* fine on
> Kubernetes 1.36 and then silently produces **zero VulnerabilityReports forever**: the
> scan Jobs run and complete, but newer Kubernetes adds Job conditions
> (`SuccessCriteriaMet`, `FailureTarget`) that the old operator does not recognise, so it
> never reads the results back. The only symptom is an empty
> `kubectl get vulnerabilityreports -A` and this, on repeat, in
> `kubectl logs -n trivy-system deploy/trivy-operator`:
>
> ```
> "msg":"Reconciler error", ... "error":"unrecognized scan job condition: SuccessCriteriaMet"
> ```
>
> Worth remembering as a shape: a security tool that reports *nothing* looks exactly like a
> clean bill of health.

> ⚠️ If you did exercise 3, the `bad` namespace has **no running workloads** — PSA rejected
> them — so it has no reports either. Either query the `good` namespace, or remove the label
> first: `kubectl label ns bad pod-security.kubernetes.io/enforce- && kubectl rollout restart deploy/web -n bad`.

These are CRDs you can query, RBAC, dashboard against, ship to Prometheus, etc. **Continuous** is the keyword — every time someone deploys, you get a fresh scan.

```bash
$ kubectl get vulnerabilityreports -n good -o json \
   | jq -r '.items[] | "\(.metadata.name): \(.report.summary.criticalCount) crit / \(.report.summary.highCount) high"'
$ kubectl get configauditreports -n good -o json \
   | jq -r '.items[].report.checks[] | select(.success == false) | "\(.severity)\t\(.checkID)\t\(.title)"' | sort -u
```

> ✅ Expected (measured 2026-08-24, chart 0.35.0 with `trivy.ignoreUnfixed=true`, so these
> are CVEs with a fix available): one `VulnerabilityReport` for the `web` ReplicaSet
> reading `0 crit / 6 high` for `nginxinc/nginx-unprivileged:1.29-alpine`, and a
> single failing config-audit check, `MEDIUM AVD-KSV-0125 Restrict container images to
> trusted registries` — the same Docker Hub finding exercise 4 left behind. CVE feeds move
> daily; expect the high count to drift by a handful in either direction.

**Then go and look at the `bad` namespace, and notice the punchline**: with its PSA label
removed so its pod can run, `nginx:latest` scores **0 crit / 0 high**, while the hardened
workload in `good` has a stack of them. `latest` was rebuilt this morning; the pinned
`1.29-alpine` tag was built months ago. A hardened pod spec does not patch a base image,
and a pinned tag stops being safe the moment you stop bumping it. These are two different
controls that people routinely conflate — exercises 1–4 fixed the pod spec and did nothing
whatsoever about the CVEs.

Note also what the operator adds over the static scans in exercises 1–2: it scans **what is
actually running**, including images someone deployed by hand, sidecars injected by a
mutating webhook, and the SA tokens and RBAC bindings that exist only in the live cluster.
Static manifest scanning cannot see any of that. The two are complements, not alternatives.

---

## 💡 Key Concepts

| Concept                           | TL;DR                                                                                                   |
|-----------------------------------|---------------------------------------------------------------------------------------------------------|
| **Pod Security Standards (PSS)**  | Three profiles — `privileged` (no restrictions), `baseline` (blocks known escalations: privileged, host namespaces, hostPath, most capabilities) and `restricted` (baseline + non-root + `RuntimeDefault` seccomp + drop ALL caps). Applied per namespace via `pod-security.kubernetes.io/{enforce,audit,warn}` labels. |
| **PodSecurityPolicy (PSP)**       | **Removed in Kubernetes v1.25 — it does not exist.** Deprecated in 1.21, gone in 1.25. Any tutorial still teaching PSP predates 2022. Its replacements are PSA/PSS (built in) or an admission controller (Kyverno / Gatekeeper) when you need more than three fixed profiles. |
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
- [Kubernetes: encrypting Secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) — the exercise 5b gap
- [Migrating from PSP](https://kubernetes.io/docs/tasks/configure-pod-container/migrate-from-psp/)

➡️ Next: [Lab 07 — Infrastructure as Code](../07-infrastructure-as-code/)
