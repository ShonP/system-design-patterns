# Changelog — Kubernetes Enterprise Platform

## 2026-08-21 (correctness audit — first end-to-end execution)

This lab had never been executed against a real cluster. Running all ten notebooks from a
cold `minikube` revealed defects in every category the review brief warns about: demos
that could not reproduce the failure they described, prose contradicted by the notebook's
own output, and a shell cell capable of committing to the reader's own git repository.

### Fixed — things that did not work at all

- **`manifests/deployment.yaml`, notebooks 02/04/08**: added `imagePullPolicy:
  IfNotPresent` to every container using a locally built `k8s-lab/*:latest` image.
  Kubernetes defaults the policy to `Always` for any `:latest` tag, so the kubelet ignored
  the image sitting in the cluster's store, tried to pull `docker.io/k8s-lab/...`, and
  every pod went to `ImagePullBackOff`. Notebooks 03–10 all failed downstream of this.
- **Notebook 02**: replaced `minikube image build` (which fails on minikube 1.38 with
  "the Dockerfile cannot be empty") with `docker build` plus a cluster-aware load step —
  `minikube image load`, `kind load docker-image`, or nothing on Docker Desktop — and a
  check that the images really are visible to the cluster before deploying.
- **Notebook 03**: `minikube service api-gateway --url` blocks while holding a tunnel
  open, so the cell hung until the notebook runner killed it. Replaced with a NodePort
  probe that reports honestly whether the node IP is routable on this OS, plus a
  `kubectl port-forward` path that works everywhere. Same fix for the Ingress test, which
  used `curl http://$(minikube ip)/` — unreachable on macOS and Windows with the docker
  driver.
- **Notebook 07**: `cp -R manifests ...` used the wrong relative path (the notebook runs
  from `notebooks/`), so the scratch GitOps repo was never created. The later `%%bash`
  cells then `cd`'d into a directory that did not exist — a warning, not an error — and
  ran `git commit` and `git revert --no-edit HEAD` **in the enclosing repository**. During
  verification this produced two real commits in this repo. All git commands now run with
  an explicit `cwd=` through a helper that refuses to run outside a git working tree.
- **Notebook 08**: `kubectl rollout restart deployment --all` is not valid (`rollout
  restart` has no `--all` flag). It exited non-zero, which does not fail a notebook cell,
  so sidecar injection silently never happened and the entire mesh section operated on
  pods with no proxy. Now `kubectl rollout restart deployment -n k8s-lab`.
- **Notebook 08**: Istio's `istio-init` container needs `NET_ADMIN`/`NET_RAW`, which the
  `k8s-lab` namespace's `pod-security.kubernetes.io/enforce: baseline` label rejects. The
  notebook now relaxes the namespace to `privileged` for the mesh section, explains that
  the production answer is the Istio CNI plugin, and **restores `baseline` in cleanup** —
  leaving it relaxed silently disabled the protection notebook 06 teaches. Cleanup is
  verified, because a half-finished teardown left notebooks 09 and 10 unable to create any
  pod at all.
- **Notebook 10**: the HPA cell slept 20 × 15 s = 300 s, longer than the 180 s per-cell
  budget the repo's runner uses, so the notebook always timed out. Split into a bounded
  sampling loop and a separate assertion loop.

### Fixed — demos that did not demonstrate their lesson

- **Notebook 09, "a PVC that never binds"**: requested `ReadWriteMany`/`500Gi` from
  minikube's hostPath provisioner, which ignores both capacity and access modes and bound
  it immediately. The prose then declared it `Pending` indefinitely. Rewritten to use
  `storageClassName: ""` (static provisioning with no matching PV), which stays Pending on
  any cluster, with the hostPath behaviour explained rather than papered over. Added the
  downstream symptom the text described but never showed: a pod stuck on
  `unbound immediate PersistentVolumeClaims`.
- **Notebook 02, readiness probe section**: the "with probes" cell ran `kubectl rollout
  status` *before* sampling the pod, so by the time it printed, the pod was already Ready
  and in the Service's endpoints — the exact opposite of the following markdown's claim.
  Reordered to sample the boot window, then wait.
- **Notebook 06, NetworkPolicy section**: on minikube's default CNI nothing is enforced,
  yet the markdown stated "the request above failed" and "team-alpha pods can reach the
  api-gateway but NOT the backend services". Each connectivity test now prints expected vs
  actual and asserts the right outcome for the CNI you actually have, and the prose says
  what an unenforced result means instead of asserting a block that did not happen. The
  DNS probe also used a short name, which busybox's `nslookup` fails to resolve on *any*
  cluster because it does not apply `search` domains — it looked like policy enforcement
  and was not.
- **Notebook 08, canary release**: the 90/10 traffic split was never observed ("the
  easiest place to see it is in Kiali later"). Now counts per-pod access-log lines before
  and after 120 requests and asserts both subsets received traffic with v1 in the majority.
- **Notebook 05, alert exercise**: told the reader to wait two minutes and look at the
  Prometheus UI. Now queries the rules API and asserts that
  `DeploymentHasNoAvailableReplicas` and `absent(up{...})` fire while `up == 0` stays
  inactive — which is the whole point of the section — and that all three resolve when the
  service comes back.
- **Notebook 08, sidecar detection**: Istio 1.30 on Kubernetes 1.29+ injects the proxy as
  a *native sidecar* in `spec.initContainers`, not `spec.containers`. Added a helper and a
  section explaining it, since anything looking only at `spec.containers` concludes there
  is no sidecar.

### Fixed — leaks and hand-off

- **Notebook 04**: `helm uninstall my-redis` leaves the chart's three 8 Gi
  `volumeClaimTemplates` PVCs behind. Now removed, with a note pointing at notebook 09's
  explanation of why Kubernetes keeps them.
- **Notebook 05**: cleanup now actually uninstalls kube-prometheus-stack (it was
  commented out) so notebook 08's Istio install has room on a 6 GB cluster. metrics-server
  is deliberately kept — notebook 10's HPA needs it.
- **Notebook 10**: cleanup scales `api-gateway` back to 2 replicas. Deleting an HPA leaves
  the Deployment at whatever the autoscaler last set, which quietly left the namespace
  over-provisioned for every re-run.
- **Notebook 01**: `--memory=8192` is a hard failure on an 8 GB Docker Desktop, because
  the minikube node is a container inside that allocation. The cell now reads Docker's own
  limit and computes the largest safe size (floor 6144, ceiling 8192). Every notebook's
  preflight hint updated to match.
- **Notebook 06**: `kubectl run test-pod` / `good-pod` / `auto-limits-pod` failed with
  `AlreadyExists` on a second run; all are now delete-then-create.
- **Notebook 05**: port-forwards hard-coded 9090 and 3000. If either is busy,
  `kubectl port-forward` exits immediately and every later request fails with an error
  that looks like a Prometheus fault. Now falls back to a free port and retries.

### Added — assertions

Every notebook now ends each demonstration with a check, so a lab that stops reproducing
its own lesson fails loudly instead of printing a checkmark. Notably: the stalled rollout
really stalls with three pods still serving and exactly one in `ImagePullBackOff`; the
Service with a typo'd selector really has zero endpoints; `helm rollback` restores the
Service as well as the Deployment and becomes revision 3; `kubectl auth can-i` returns all
four least-privilege answers; a privileged pod really is refused at admission; ArgoCD's
self-heal really recreates the object (checked by UID, not by absence — it is far too fast
to catch mid-delete); the OOM demo really reports exit code 137; the throttle demo really
accumulates `nr_throttled` while staying Ready; and the HPA really scales past
`minReplicas` with observed CPU above the 60 % target.

### Fixed — the cluster falling over, and cells outliving their budget

Running the notebooks one at a time passes; running all ten back to back on a 6 GB cluster
did not, and the failure was not a Kubernetes error — the whole node stopped answering
(`Unable to connect to the server: net/http: TLS handshake timeout`) partway through, so
every notebook after it failed in its preflight. Two causes, both worth knowing:

- **The kubelet reports the host's memory, not the node container's limit.** With the
  docker driver on macOS, a cluster started with `--memory=6144` reports ~7.6 GiB of
  allocatable memory. The scheduler happily fills past the real ceiling, the kubelet never
  observes memory pressure so it never evicts anything, and Docker stalls or kills the
  whole node container instead. Notebook 01 now prints a warning when the reported capacity
  exceeds what minikube was given, and explains what the failure looks like.
- **`manifests/prometheus-values.yaml` was sized for a bigger cluster.** Retention dropped
  24h → 2h, WAL compression on, Prometheus requests 512Mi → 400Mi, and
  `defaultRules.create` is now `false` — the chart's ~100 built-in rules are re-evaluated
  every 30 s, several of them fire permanently on a single-node cluster, and notebook 05
  writes the only rules it needs. Node disk reads over a full run went from ~530 GB to
  ~3 GB. Notebook 08 additionally frees the monitoring stack before installing Istio (set
  `FREE_MONITORING = False` to keep it), so the sequence survives notebook 05 being skipped.

Separately, the repo's runner (`tools/run_labs.py`) allows a notebook cell **180 seconds**,
and several cells could block far longer than that on a cold cluster. Fixed by splitting
each long wait across two cells with an explicit budget, rather than one
`--wait --timeout 10m`:

- notebook 03's `kubectl wait --timeout=300s` for the ingress controller,
- notebook 04's and notebook 05's `helm ... --wait` installs (now install, then poll),
- notebook 07's four sequential ArgoCD rollout waits,
- notebook 08's istiod wait, sidecar-injection restart, canary rollout and addon waits,
- notebook 02's three-deployment hand-off and its probe section.

Three races were also fixed, all of the "passes on my machine" kind:

- notebook 02 ran `kubectl wait --for=condition=Ready pod -l app=probe-demo` while the
  rollout was still terminating the old pod. A label selector matches the pod that is going
  away, and kubectl waits for it to become Ready, which it never will.
- notebook 05 asserted a ServiceMonitor target was healthy as soon as it appeared. A
  freshly discovered target reports `health: unknown` until the first scrape completes.
- notebook 05 asserted its alert rules were `inactive` immediately after loading them. A
  rule reports `state: unknown` until Prometheus has evaluated it once.
