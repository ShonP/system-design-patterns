# Lab 04 — Container Security: Insecure vs Secure Dockerfiles

## 🎯 What you'll learn

- Why naive Dockerfiles ship with hundreds of CVEs and admin-level RCE-friendly defaults
- Apply the "**big four**" hardening techniques: minimal base, multi-stage, non-root, no secrets
- Use **Hadolint** to catch Dockerfile mistakes statically
- Use **Trivy** to scan the built images and quantify the improvement
- Run **Docker Bench for Security** to audit your Docker host
- Read CIS benchmarks (Docker / containerd) and what's worth implementing

## 📋 Prerequisites

- Docker
- Lab 01 done (or comfortable with Trivy basics)

## 🔧 Setup

This lab has two parallel apps — same Node.js TODO API, two Dockerfiles:

```text
04-container-security/
├── insecure/Dockerfile     # the "I copy-pasted from a tutorial" version
├── secure/Dockerfile       # the production version
└── (same app source in both)
```

```bash
$ cd 04-container-security
$ docker compose build      # builds both images
$ ./scripts/run-trivy.sh --version
$ ./scripts/run-hadolint.sh --version
```

---

## 📝 Exercises

### Exercise 1 — Static analysis of both Dockerfiles with Hadolint

```bash
$ ./scripts/run-hadolint.sh insecure/Dockerfile
$ ./scripts/run-hadolint.sh secure/Dockerfile
```

> ✅ Expected: many DL3xxx / SC2xxx warnings on `insecure/`, near-zero on `secure/`.

Note what Hadolint catches:

- `DL3002` — running as root
- `DL3008` — unpinned `apt-get install`
- `DL3009` — no `apt-get clean`
- `DL3007` — `:latest` tag
- `DL4006` — missing `set -o pipefail` in shell `RUN`

### Exercise 2 — Vulnerability scan of both images

```bash
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL securitylabs/todo-insecure:latest > exercises/insecure.txt
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL securitylabs/todo-secure:latest   > exercises/secure.txt
$ wc -l exercises/insecure.txt exercises/secure.txt
```

Image-size diff (often the most concrete metric for an exec):

```bash
$ docker images securitylabs/todo-insecure:latest --format "{{.Size}}"
$ docker images securitylabs/todo-secure:latest   --format "{{.Size}}"
```

> ✅ Expected: secure image is 5–20× smaller and has dramatically fewer CVEs.

### Exercise 3 — Inspect what's actually in each image

```bash
$ ./scripts/run-syft.sh securitylabs/todo-insecure:latest -o table | wc -l
$ ./scripts/run-syft.sh securitylabs/todo-secure:latest   -o table | wc -l
```

The insecure image ships dozens of OS packages you don't need (perl, python, build tools, libssl-dev, gcc, …). Each one is attack surface and CVE candidate.

### Exercise 4 — Run as non-root: prove it

```bash
$ docker run --rm securitylabs/todo-insecure:latest id
uid=0(root) gid=0(root) groups=0(root)

$ docker run --rm securitylabs/todo-secure:latest id
uid=10001(app) gid=10001(app) groups=10001(app)
```

> 💡 Why this matters: a remote-code-execution bug in your Node app + `USER root` = a container that can `write` to the kernel keyring, install packages, mount things, etc. Defense in depth.

### Exercise 5 — Drop capabilities and read-only filesystem

```bash
$ docker run --rm \
    --read-only \
    --cap-drop=ALL \
    --security-opt=no-new-privileges \
    --tmpfs /tmp \
    -p 3000:3000 \
    securitylabs/todo-secure:latest &

$ curl localhost:3000/todos
$ kill %1
```

If you tried this with the `insecure` image, things might break (some tutorials write to `/app`, expect root to install on first boot, etc.). The secure one is built to run with these flags.

### Exercise 6 — Docker Bench for Security on your host

This is a CIS Docker Benchmark audit of the Docker daemon **on your machine**. Read-only — it doesn't change anything.

```bash
$ ./scripts/run-docker-bench.sh
```

Skim the output. Common findings on dev laptops (and what to do):

| Finding              | Severity | Action                                    |
|----------------------|----------|-------------------------------------------|
| `1.1.1` audit rules  | INFO     | Server-only concern — ignore on laptop.   |
| `2.x` daemon flags   | WARN     | Tune `daemon.json` per CIS recommendations.|
| `4.1` images as root | WARN     | Add `USER` to all your Dockerfiles.       |
| `5.x` runtime flags  | WARN     | Add to `docker run` / compose runtime.    |

### Exercise 7 — Distroless / scratch (advanced)

Look at `secure/Dockerfile.distroless` — it uses `gcr.io/distroless/nodejs20-debian12:nonroot`. Build and rescan:

```bash
$ docker build -f secure/Dockerfile.distroless -t securitylabs/todo-distroless:latest secure/
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL securitylabs/todo-distroless:latest
$ docker images securitylabs/todo-distroless:latest --format "{{.Size}}"
```

> ✅ Expected: image is ~tens of MB, single-digit (or zero) HIGH CVEs at scan time.

### Exercise 8 — Sign and verify (supply-chain)

Use [`cosign`](https://docs.sigstore.dev/cosign/overview/) to sign the secure image with a keyless OIDC flow (run locally — no SaaS account):

```bash
$ ./scripts/run-cosign.sh sign --yes --tlog-upload=false \
    --key generated-key securitylabs/todo-secure:latest
$ ./scripts/run-cosign.sh verify \
    --key generated-key.pub --insecure-ignore-tlog securitylabs/todo-secure:latest
```

> 💡 In production this is keyless via OIDC + Sigstore Rekor; here we use a local key so you can run offline.

---

## 💡 Key Concepts

### The big four hardening rules

1. **Minimal base image.** Prefer `distroless`, `*-slim`, `alpine` (pick once per org). Avoid `:latest`.
2. **Multi-stage builds.** Build artifacts in a fat image; `COPY --from=build` only what you ship.
3. **Non-root user.** `RUN useradd -u 10001 -m app && USER app`. Don't run pid 1 as root.
4. **No baked-in secrets.** Mount via env / secrets manager. Never `ENV API_KEY=...`.

### Runtime hardening (defense in depth)

```bash
docker run \
  --read-only \                 # rootfs immutable
  --cap-drop=ALL \              # drop all Linux capabilities
  --security-opt=no-new-privileges \
  --pids-limit=200 \            # bound fork bombs
  --memory=512m --cpus=1 \      # bound resource exhaustion
  --tmpfs /tmp:rw,noexec,nosuid \
  --user 10001:10001 \
  IMAGE
```

### Why scanners hate `node:14`

```text
node:14   = node 14 (EOL) + Debian 11 + npm 6 + global packages
            ^^             ^^^^^^^^^^   ^^^^^   ^^^^^^^^^^^^^^^^
            CVEs           CVEs         CVEs    CVEs

node:20-alpine = node 20 + Alpine (musl, busybox)
distroless     = node 20 + nothing else
```

### CIS Docker Benchmark in 30 seconds

Sections you actually care about:

- **§4 — Container Images and Build File** (USER, HEALTHCHECK, no secrets)
- **§5 — Container Runtime** (no `--privileged`, drop caps, no host network/PID)
- **§7 — Docker Swarm Configuration** (only if you use Swarm; most don't)

---

## 🏆 Challenge

1. **Get a 0-CVE image.** Start from `chainguard/node:latest` (or `cgr.dev/chainguard/node`) and build the TODO API. Verify with Trivy. Document any code changes required.
2. **Multi-arch + signed.** Use `docker buildx` to build linux/amd64 + linux/arm64. Sign both with cosign; demonstrate verification picks the correct arch.
3. **`HEALTHCHECK` + graceful shutdown.** Add `HEALTHCHECK` to the secure Dockerfile, plus SIGTERM handling in the app. Verify with `docker stop` that no requests are dropped.
4. **CI gate.** Write a GitHub Actions workflow that fails the PR if Trivy finds any new HIGH/CRITICAL CVE compared to the baseline image on `main`.

---

## 📚 Further reading

- [Docker security cheat sheet (OWASP)](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Distroless images](https://github.com/GoogleContainerTools/distroless)
- [Chainguard Images](https://images.chainguard.dev/)
- [Hadolint rules](https://github.com/hadolint/hadolint/wiki)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Sigstore / cosign docs](https://docs.sigstore.dev/)
- `research-report.md` §2.1, §4.4 in this repo

➡️ Next: [Lab 05 — Web App Security (OWASP Juice Shop + ZAP)](../05-web-app-security-owasp/)
