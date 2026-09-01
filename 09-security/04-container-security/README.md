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
├── insecure/Dockerfile.tmpl  # the "I copy-pasted from a tutorial" version
│                            # → rendered to insecure/Dockerfile by plant-secrets.sh
├── secure/Dockerfile       # the production version
└── (same app source in both)
```

```bash
$ cd 04-container-security
$ ./scripts/plant-secrets.sh                  # renders insecure/Dockerfile from its template
$ docker compose --profile build-only build   # builds both images
$ ./scripts/run-trivy.sh --version
$ ./scripts/run-hadolint.sh --version
```

> ⚠️ Both build services sit behind the `build-only` profile — a bare `docker compose build`
> builds nothing at all. Naming a service (`docker compose build todo-secure`) also works.

> 🔑 **`insecure/Dockerfile` is generated, and the build fails without it.** Exercise 2
> depends on the planted `ENV API_KEY=` being shaped like a real Stripe key — with a
> placeholder Trivy reports zero, which is the trap documented in that exercise. A
> real-shaped key in a committed file is also exactly what GitHub's push protection
> blocks, so the repo carries `insecure/Dockerfile.tmpl` and `plant-secrets.sh`
> substitutes a freshly generated key. The template is line-for-line identical to the
> output, so the `Dockerfile:9` references below still land on the right line. Re-run with
> `--force` to rotate the key (this invalidates the build cache).

> 🔧 Every `scripts/run-*.sh` runs the native binary if it is on your `PATH` and otherwise
> falls back to a pinned Docker image (Hadolint 2.12.0, Trivy 0.58.1, Syft 1.18.1, cosign
> 2.4.1). You can do the whole lab with only Docker installed. The one place it is worth
> installing the real thing is `brew install cosign` for exercise 8 — but read that exercise
> first, because Homebrew now ships cosign **v3**, whose signing flags differ from the
> pinned v2 fallback's.

**Keep the two halves of this lab separate in your head.** Everything up to exercise 3 is
about *what is inside the image* (packages, CVEs, size). Everything from exercise 4 on is
about *how the container is run* (user, capabilities, filesystem, syscalls). They fail
independently: a distroless image with zero CVEs running `--privileged` as root with the
Docker socket mounted is a worse outcome than a fat Debian image with 200 CVEs running
unprivileged with a read-only rootfs and all capabilities dropped. Image scanning is the
part everyone does, and runtime configuration is the part that decides the blast radius.

---

## 📝 Exercises

### Exercise 1 — Static analysis of both Dockerfiles with Hadolint

```bash
$ ./scripts/run-hadolint.sh insecure/Dockerfile
$ ./scripts/run-hadolint.sh secure/Dockerfile
```

> ✅ Expected on `insecure/Dockerfile`: exactly **four** findings — `DL3007` (`:latest`
> tag), `DL3008` (unpinned `apt-get install`), `DL3015` (no `--no-install-recommends`) and
> `DL3009` (no `apt-get clean`) — and exit status 1. `secure/Dockerfile` and
> `secure/Dockerfile.distroless` both come back completely clean: no output, exit 0.
> Measured 2026-08-21 with Hadolint 2.12.0.
>
> When the script falls back to the Docker image it pipes the file in on stdin, so findings
> are prefixed `-:7` rather than `insecure/Dockerfile:7`. That dash is the filename.

**Now notice what Hadolint does *not* say.** Two of the worst things about
`insecure/Dockerfile` produce no warning at all:

- **It never sets `USER`, so the container runs as root.** Hadolint's `DL3002` is
  *"last USER should not be root"* — it fires when you explicitly write `USER root`, and
  says nothing when you simply omit `USER`. The most common root-cause of "everything runs
  as root" is invisible to the linter.
- **`ENV API_KEY=sk_live_...` bakes a credential into an image layer**, readable by anyone
  who can `docker pull` it, forever, even if a later layer deletes it. Hadolint has no
  rule for that; `trivy image --scanners secret` does:

```bash
$ ./scripts/run-trivy.sh image --scanners secret securitylabs/todo-insecure:latest
$ docker history --no-trunc securitylabs/todo-insecure:latest | grep -i api_key
```

> ✅ Expected: **3 CRITICAL `stripe-secret-token` findings**, in two different targets.
> One is `/app/Dockerfile:9` — the insecure build context has no `.dockerignore`, so
> `COPY . .` ships the Dockerfile *inside the image*. The other two are in the target named
> after the image itself: Trivy also scans the **image config JSON**, where the `ENV` lives
> both as a config value and as a build-history entry. `docker history` shows you the same
> layer from the other side. Measured 2026-08-21, Trivy 0.58.1.
>
> ⚠️ A placeholder has to be *shaped* like the real thing or no scanner will look at it.
> Trivy's built-in allow-rules discard any candidate containing the string `EXAMPLE`, which
> is exactly what a well-meaning fake credential usually says. An earlier version of this
> lab planted `sk_live_EXAMPLE_FAKE_KEY_FOR_LAB` and the secret scanner found **zero**
> findings — the lesson silently taught the opposite of the truth. If you are seeding test
> secrets for your own pipeline, always confirm your scanner actually fires on them.

Three rules that "should" be here are absent, and each absence has a reason:
`DL3016` (pin versions in `npm install`) only flags `npm install <package>`, and line 12 is
a bare `npm install`. `DL3059` (consecutive `RUN`s) needs the `RUN`s to be adjacent, and
two `ENV` lines sit between them. `DL4006` (`set -o pipefail`) only applies to `RUN` lines
containing a pipe. Never take an expected-findings list on faith, including this one: run
it and compare.

### Exercise 2 — Vulnerability scan of both images

```bash
$ mkdir -p exercises
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL securitylabs/todo-insecure:latest > exercises/insecure.txt
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL securitylabs/todo-secure:latest   > exercises/secure.txt
$ wc -l exercises/insecure.txt exercises/secure.txt

# A number you can actually compare, rather than counting table rows:
$ for i in todo-insecure todo-secure; do
    printf "%-14s " "$i"
    ./scripts/run-trivy.sh image --severity HIGH,CRITICAL --format json "securitylabs/${i}:latest" \
      | jq '[.Results[].Vulnerabilities // [] | length] | add // 0'
  done
```

> ⚠️ Those braces are load-bearing on macOS. zsh applies *history modifiers* to an
> unbraced expansion, so `"securitylabs/$i:latest"` parses as `$i` with the `:l`
> (lowercase) modifier followed by the literal `atest` — you get
> `securitylabs/todo-insecureatest` and a confusing `UNAUTHORIZED` error from Docker Hub,
> because Trivy fell through to looking the name up remotely. bash does not do this. Write
> `${i}` and it is correct in both shells.

Image-size diff (often the most concrete metric for an exec):

```bash
$ docker images securitylabs/todo-insecure:latest --format "{{.Size}}"
$ docker images securitylabs/todo-secure:latest   --format "{{.Size}}"
```

> ✅ Expected: the secure image is roughly 5–20× smaller and has an order of magnitude
> fewer HIGH/CRITICAL CVEs. Measured 2026-08-21 with Trivy 0.58.1 (DB 2026-08-21):
>
> | image           | size   | HIGH+CRITICAL | all severities |
> |-----------------|--------|---------------|----------------|
> | `todo-insecure` | 1.84GB | 470           | 2997           |
> | `todo-secure`   | 199MB  | 20            | 57             |
>
> CVE counts drift every time the feed updates — expect the same shape, not the same
> integers.
>
> **Now split those counts by where they come from**, because the headline hides something:
>
> ```bash
> $ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL --format json \
>       securitylabs/todo-secure:latest | jq -r '.Results[] | "\(.Target): \((.Vulnerabilities//[])|length)"'
> ```
>
> The insecure image's 470 are 467 Debian packages + 3 npm. The secure image's 20 are only
> 2 Alpine packages — but **18 npm**, and every one of them lives in
> `/usr/local/lib/node_modules`, which is *npm's own bundled dependency tree*, not your
> app's. `node:20-alpine` pins an EOL Node 20, so its shipped npm is frozen and its `tar`,
> `minimatch` and `brace-expansion` copies never get patched. You did not install those and
> you never call them. This is why exercise 7 matters: distroless has no npm at all.

### Exercise 3 — Inspect what's actually in each image

```bash
$ ./scripts/run-syft.sh securitylabs/todo-insecure:latest -o table | wc -l
$ ./scripts/run-syft.sh securitylabs/todo-secure:latest   -o table | wc -l
```

`wc -l` on a table is a crude proxy. Count by ecosystem instead:

```bash
$ for i in todo-insecure todo-secure; do
    echo "== $i"
    ./scripts/run-syft.sh "securitylabs/${i}:latest" -o json \
      | jq -r '.artifacts[].type' | sort | uniq -c | sort -rn
  done
```

> ✅ Measured 2026-08-21 with Syft 1.18.1:
>
> | image           | deb | apk | npm | python | total |
> |-----------------|-----|-----|-----|--------|-------|
> | `todo-insecure` | 454 | –   | 213 | 2      | 670   |
> | `todo-secure`   | –   | 18  | 273 | –      | 292   |

The **OS** layer is where the win is: 454 Debian packages (perl, python3, gcc,
build-essential, libssl-dev, …) against 18 Alpine ones. Each is attack surface and a CVE
candidate, and it is the reason the Debian image carries 467 OS CVEs to Alpine's 2.

But read the npm column honestly: the "secure" image ships **more** npm packages than the
insecure one, because `node:20-alpine`'s bundled npm drags in a larger dependency tree than
the newer npm in `node:latest`. Your app needs 68 of those. A smaller image is not
automatically a smaller SBOM — check both.

### Exercise 4 — Run as non-root: prove it

```bash
$ docker run --rm securitylabs/todo-insecure:latest id
uid=0(root) gid=0(root) groups=0(root)

$ docker run --rm securitylabs/todo-secure:latest id
uid=10001(app) gid=10001(app) groups=10001(app),10001(app)
```

> 💡 Why this matters: a remote-code-execution bug in your Node app + `USER root` = a container that can `write` to the kernel keyring, install packages, mount things, etc. Defense in depth.

### Exercise 5 — Drop capabilities and read-only filesystem

```bash
$ docker run --rm -d --name todo-hardened \
    --read-only \
    --cap-drop=ALL \
    --security-opt=no-new-privileges \
    --tmpfs /tmp \
    -p 3100:3000 \
    securitylabs/todo-secure:latest

$ curl -s localhost:3100/todos
$ curl -s -X POST localhost:3100/todos -H 'content-type: application/json' -d '{"text":"hi"}'
$ docker rm -f todo-hardened
```

> Port 3100, not 3000 — 3000 is Juice Shop's port in lab 05 and is the single most
> contended port on a developer laptop. Change it freely; nothing here depends on it.

Prove each flag is doing something, rather than trusting the flag names:

```bash
# --read-only really is read-only:
$ docker run --rm --read-only securitylabs/todo-secure:latest sh -c 'touch /app/x'
touch: /app/x: Read-only file system

# --cap-drop=ALL really drops capabilities. Run as root, or there is nothing to drop:
$ docker run --rm --user 0 securitylabs/todo-secure:latest sh -c 'chown 99 /app/server.js && echo OK'
OK
$ docker run --rm --user 0 --cap-drop=ALL securitylabs/todo-secure:latest sh -c 'chown 99 /app/server.js && echo OK'
chown: /app/server.js: Operation not permitted

# USER in the image is only a default:
$ docker run --rm --user 0 securitylabs/todo-secure:latest id
uid=0(root) gid=0(root) groups=0(root),0(root),1(bin),...
```

> ⚠️ **`ping` is the classic demo of `--cap-drop=ALL` and it does not work any more.**
> Plenty of tutorials tell you to run `ping -c1 127.0.0.1` with all capabilities dropped and
> watch it fail for want of `CAP_NET_RAW`. Try it here and it succeeds. Modern busybox and
> iputils open an ICMP **datagram** socket rather than a raw one, which needs no capability
> at all as long as the caller's gid falls inside `net.ipv4.ping_group_range` — and Docker
> Desktop's VM ships that wide open:
>
> ```bash
> $ docker run --rm --cap-drop=ALL securitylabs/todo-secure:latest sh -c 'cat /proc/sys/net/ipv4/ping_group_range'
> 0	2147483647
> ```
>
> That is why the check above uses `chown`, which still genuinely requires `CAP_CHOWN`. The
> general lesson is the one this whole lab keeps repeating: a control you have not watched
> *fail* is a control you have not tested.

That last one is the point worth remembering: **`USER app` in a Dockerfile is a default,
not a control.** Anyone who can start the container can override it with `--user 0`, and
Kubernetes will happily do so unless `runAsNonRoot: true` is enforced by admission (lab 06).
Image-level hardening is a good default; runtime policy is the enforcement.

### Exercise 6 — Docker Bench for Security on your host

This is a CIS Docker Benchmark audit of the Docker daemon **on your machine**. Read-only — it doesn't change anything.

```bash
$ ./scripts/run-docker-bench.sh
```

> ⚠️ **This tool is broken out of the box, and the script above is a repair.** Both of the
> reasons are worth understanding, because they are what an unmaintained security tool
> looks like from the inside.
>
> **(1) Its bundled Docker client is too old to talk to your daemon.**
> `docker/docker-bench-security` ships Docker 18.06.1-ce, which speaks API 1.38. Engine 25
> and later refuse anything below API 1.44. Run the upstream command unmodified and every
> check that shells out to `docker` prints `Error connecting to docker daemon (does docker
> ps work?)` — the run produces no findings at all. `run-docker-bench.sh` sets
> `DOCKER_API_VERSION=1.44` to force the old client onto an API the daemon still accepts.
>
> **(2) On Docker Desktop, `-v /etc:/etc:ro` stops the container from starting.** The
> upstream invocation mounts the host's `/etc`, `/var/lib`, `/usr/bin/runc` and
> `/usr/lib/systemd`. On macOS none of those belong to the daemon — dockerd runs in a Linux
> VM — and mounting `/etc` read-only makes runc fail outright:
> `create mountpoint for /etc/hostname mount: read-only file system`, exit 125, zero output.
> The script therefore adds those mounts **only on Linux**.
>
> **(3) It is unmaintained.** Upstream archived it; it grades CIS Docker Benchmark 1.x-era
> controls. Treat it as a teaching artifact for the *shape* of a benchmark audit. For a
> maintained equivalent use `trivy image --scanners misconfig` on your Dockerfiles plus
> kube-bench (lab 06) on the cluster side.

**Which sections mean anything on Docker Desktop?** The split is not "1–3 bad, 4–5 good" —
it is *how each section gets its evidence*:

| Section | Source of truth                        | Valid on Docker Desktop?                    |
|---------|----------------------------------------|---------------------------------------------|
| §1 Host | files + auditctl on the daemon's host  | ❌ noise — reads your Mac, not the VM        |
| §2 Daemon | `docker info` / `docker network inspect` over the socket | ✅ real — this *is* the daemon |
| §3 Daemon config files | `/etc/docker/*`, systemd units | ❌ noise — all 18 report "File not found"    |
| §4 Images | `docker inspect` of running containers | ✅ real                                     |
| §5 Runtime | `docker inspect` of running containers | ✅ real — the most useful section here      |
| §7 Swarm | `docker info`                          | ✅ real (and trivially passes if you have no Swarm) |

Measured 2026-08-21 on Docker Desktop / Engine 29.0.1, the repaired script produced
7 PASS / 7 WARN in §2, 3 WARN in §4, and 9 PASS / 16 WARN in §5. §3 was 18 × "File not
found", exactly as predicted. You will also see occasional `is_rosetta_process` assertion
traces interleaved in the output on Apple silicon — the image is linux/amd64 only and runs
under emulation. They are harmless noise, not findings.

**Make §4 and §5 about *your* images.** Out of the box those sections grade whatever
happens to be running on your laptop, which is not a lesson. Start the two lab images side
by side and read the difference — this is exercise 5 graded by a benchmark:

```bash
$ docker run -d --rm --name todo-naive -p 3101:3000 securitylabs/todo-insecure:latest
$ docker run -d --rm --name todo-hard \
    --read-only --cap-drop=ALL --security-opt=no-new-privileges \
    --pids-limit=200 --memory=512m --tmpfs /tmp \
    -p 3102:3000 securitylabs/todo-secure:latest

$ ./scripts/run-docker-bench.sh 2>/dev/null | grep -E 'todo-naive|todo-hard'

$ docker rm -f todo-naive todo-hard
```

> ✅ Expected: `todo-hard` is absent from every check below, and `todo-naive` is flagged by
> all of them. Measured 2026-08-21:
>
> | Check | Meaning | flags `todo-naive` | flags `todo-hard` |
> |-------|---------|--------------------|-------------------|
> | `4.1`  | container runs as root        | ✅ | — |
> | `5.10` | no memory limit               | ✅ | — |
> | `5.12` | root filesystem is read/write | ✅ | — |
> | `5.25` | can acquire new privileges    | ✅ | — |
> | `5.26` | no runtime health check       | ✅ | — |
> | `5.28` | no PIDs cgroup limit          | ✅ | — |
>
> Both are still flagged by `5.1` (no AppArmor profile — not a thing on Docker Desktop),
> `5.11` (no CPU limit), `5.13` (published on `0.0.0.0`) and `5.14` (restart policy). Those
> four are the honest remaining gap, and `--cpus=1`, `-p 127.0.0.1:3102:3000` and
> `--restart=on-failure:5` close three of them.

### Exercise 7 — Distroless / scratch (advanced)

Look at `secure/Dockerfile.distroless` — it uses `gcr.io/distroless/nodejs20-debian12:nonroot`. Build and rescan:

```bash
$ docker build -f secure/Dockerfile.distroless -t securitylabs/todo-distroless:latest secure/
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL securitylabs/todo-distroless:latest
$ docker images securitylabs/todo-distroless:latest --format "{{.Size}}"

# An image that scans clean but cannot start is not an improvement. Always run it:
$ docker run --rm -d --name todo-distroless -p 3103:3000 securitylabs/todo-distroless:latest
$ curl -s localhost:3103/health
{"ok":true}
$ docker rm -f todo-distroless
```

> ✅ Expected: single-digit HIGH/CRITICAL CVEs. Measured 2026-08-21 with Trivy 0.58.1:
> **7 HIGH/CRITICAL** (42 across all severities), against 20 for `todo-secure` and 470 for
> `todo-insecure`. The whole 20 → 7 improvement is the disappearance of npm: distroless has
> no package manager, so npm's 18 unpatchable bundled CVEs from exercise 2 simply are not
> there. What remains is Debian 12 userspace — mostly OpenSSL.
>
> ⚠️ **Size is the claim that does not survive contact.** Distroless is widely sold as
> "tens of MB"; this image measures **186MB**, barely under `todo-secure`'s 199MB. A Node
> runtime is ~110MB of V8 no matter who packages it, and `node_modules` is the same in both.
> Distroless buys you *fewer packages and no shell*, not a small image. If you want the size
> win too, you need a runtime that can be statically linked or tree-shaken — which for Node
> means a bundler, not a base image.
>
> 💡 The `COPY --from=build --chown=nonroot:nonroot /app /app` in that Dockerfile is not
> decoration. `COPY` preserves the source file mode, the files in this repo are `0600`, and
> distroless has no `root` shell to fix them up afterwards — drop the `--chown` and the
> image builds fine, scans clean, and dies on startup with
> `Error: EACCES: permission denied, open '/app/server.js'`. Non-root images and file
> ownership are the same problem.

### Exercise 8 — Sign and verify (supply-chain)

Two facts that trip everyone up the first time:

1. **cosign signs artifacts in a registry, not images in your local Docker cache.** A
   signature is stored as a second tag (`sha256-<digest>.sig`) *next to the image*. There is
   nowhere to put it if the image only exists locally, so `cosign sign
   securitylabs/todo-secure:latest` fails — it tries to resolve that name against Docker Hub.
2. **You need a key before you can use `--key`.** Nothing generates one implicitly.

So: start a throwaway registry, push, generate a key, sign, verify.

```bash
$ docker compose --profile registry up -d registry     # registry:2 on localhost:5001
$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5001/v2/   # expect 200

$ docker tag  securitylabs/todo-secure:latest localhost:5001/todo-secure:latest
$ docker push localhost:5001/todo-secure:latest

# Generates cosign.key + cosign.pub in the current directory.
# An empty password is fine for a lab; never for anything else.
$ COSIGN_PASSWORD="" ./scripts/run-cosign.sh generate-key-pair
```

> ⚠️ **5001 is a contended port** — it is a common default for small Flask/Python services,
> and `docker compose up` will fail with `Bind for 0.0.0.0:5001 failed: port is already
> allocated`. Check first with `lsof -nP -iTCP:5001 -sTCP:LISTEN`. The compose file reads
> `REGISTRY_PORT`, so if it is taken just move it — nothing here depends on 5001, only on
> the registry and the image names agreeing:
>
> ```bash
> $ REGISTRY_PORT=5051 docker compose --profile registry up -d registry
> ```
>
> and use `localhost:5051/...` everywhere below.

Signing is where the version you have starts to matter, so check it first:

```bash
$ ./scripts/run-cosign.sh version | grep GitVersion
```

**cosign v2.x** (this is what the pinned Docker fallback runs):

```bash
$ COSIGN_PASSWORD="" ./scripts/run-cosign.sh sign --yes \
    --tlog-upload=false --allow-insecure-registry \
    --key cosign.key localhost:5001/todo-secure:latest
```

**cosign v3.x** (this is what `brew install cosign` gives you today). `--tlog-upload=false`
was removed; passing it is a hard error telling you to supply a signing config instead.
Build a tlog-free one once, then sign against it:

```bash
$ cosign signing-config create --no-default-rekor --no-default-fulcio --no-default-tsa \
    --out signingconfig.json

$ COSIGN_PASSWORD="" ./scripts/run-cosign.sh sign -y \
    --signing-config signingconfig.json --allow-insecure-registry --allow-http-registry \
    --key cosign.key localhost:5001/todo-secure:latest
Pushing signature to: localhost:5001/todo-secure
```

Verification is the same on both:

```bash
$ ./scripts/run-cosign.sh verify \
    --key cosign.pub --insecure-ignore-tlog --allow-insecure-registry \
    localhost:5001/todo-secure:latest
```

> ✅ Expected: `Verification for localhost:5001/todo-secure:latest --`, then
> `The cosign claims were validated` / `The signatures were verified against the specified
> public key`, then a JSON payload whose `docker-manifest-digest` matches the digest
> `docker push` printed. Exit status 0.

**Now prove the negative — twice.** A signature check that cannot fail is not checking
anything, and the two ways it should fail are different failures:

```bash
# 1. right image, WRONG key. Generate a second pair somewhere else:
$ mkdir -p /tmp/otherkey && (cd /tmp/otherkey && COSIGN_PASSWORD="" cosign generate-key-pair)
$ ./scripts/run-cosign.sh verify --key /tmp/otherkey/cosign.pub \
    --insecure-ignore-tlog --allow-insecure-registry localhost:5001/todo-secure:latest
Error: no matching attestations: ... accepted signatures do not match threshold, Found: 0, Expected 1
# exit status 1 -- a signature exists, but not one you trust.

# 2. right key, UNSIGNED image. Push the insecure one and don't sign it:
$ docker tag securitylabs/todo-insecure:latest localhost:5001/todo-insecure:latest
$ docker push localhost:5001/todo-insecure:latest
$ ./scripts/run-cosign.sh verify --key cosign.pub \
    --insecure-ignore-tlog --allow-insecure-registry localhost:5001/todo-insecure:latest
Error: no signatures found
# exit status 10 -- nothing was ever signed.
```

> 💡 Those two exit codes are the whole reason to check exit status rather than grep the
> output. In a CI gate, `1` means "someone signed this and it was not us"; `10` means "this
> image was never signed at all". They warrant different alerts.

> 🐳 Native `cosign` (`brew install cosign`) is much easier here. The Docker fallback runs
> in its own network namespace, so `localhost:5001` means the *container's* localhost.
> **Use `--network host`** — on Docker Desktop too, where it works as long as host
> networking is enabled in Settings → Resources → Network:
>
> ```bash
> $ docker run --rm --network host -e COSIGN_PASSWORD="" -v "$(pwd)":/workspace -w /workspace \
>     gcr.io/projectsigstore/cosign:v2.4.1 sign --yes --tlog-upload=false \
>     --allow-insecure-registry --key cosign.key localhost:5001/todo-secure:latest
> ```
>
> Swapping in `host.docker.internal:5001` instead **does not work**, and the reason is worth
> knowing: `--allow-insecure-registry` only skips TLS *verification*, it does not permit
> plain HTTP. go-containerregistry falls back to HTTP for `localhost` and `127.0.0.1` only,
> so any other hostname gets `http: server gave HTTP response to HTTPS client`. Adding
> `--allow-http-registry` fixes `sign` but v2.4.1's `verify` still insists on HTTPS, so you
> can sign and then not verify — the worst of both. Stay on `localhost` + `--network host`.

> 💡 The tlog-free signing config and `--insecure-ignore-tlog` keep this exercise offline
> and keyed. Production wants the opposite: **keyless** signing, where cosign obtains a
> short-lived certificate from Fulcio by proving your identity over OIDC, and records the
> signature in Sigstore's Rekor transparency log. Note what that implies for a lab — running
> `cosign sign` *without* `--key` starts an interactive OIDC flow and opens a browser (or
> demands `--identity-token`), and it writes a public, permanent Rekor entry. That is why
> this exercise uses a local key pair: it is the same signature machinery with none of the
> external dependencies. The half you cannot practise offline is the identity half.
>
> The other half nobody practises is enforcement. A policy engine (Kyverno, Gatekeeper,
> Connaisseur) has to refuse unsigned images at admission — see lab 06. A signature nobody
> verifies at admission time is decoration.

### Exercise 9 — Close the loop: fix the insecure image

Comparing two files someone else wrote is not the same as making the change. Baseline first:

```bash
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL --format json \
      securitylabs/todo-insecure:latest | jq '[.Results[].Vulnerabilities // [] | length] | add // 0'
$ ./scripts/run-hadolint.sh insecure/Dockerfile | wc -l
$ docker images securitylabs/todo-insecure:latest --format "{{.Size}}"
```

Now apply the four changes to `insecure/Dockerfile`, rebuilding and rescanning after each
so you can attribute the improvement:

1. delete the `apt-get install curl python3 build-essential` line
2. `FROM node:latest` → `FROM node:20-alpine` (pin it)
3. delete the `ENV API_KEY=...` line
4. add a non-root user and `USER app` before `CMD`

> ⚠️ **That order matters, and it is the reverse of the obvious one.** Swap the base image
> first and the very next build dies:
>
> ```
> /bin/sh: apt-get: not found
> ERROR: process "/bin/sh -c apt-get update && apt-get install -y curl python3 build-essential"
>        did not complete successfully: exit code: 127
> ```
>
> Alpine uses `apk`, not `apt-get`. "Just change the base image" is never just changing the
> base image, and this is the smallest possible version of the migration every team hits.
> For the same reason, step 4 cannot use the `useradd` from the Key Concepts section below —
> that is Debian's. On Alpine it is
> `RUN addgroup -g 10001 -S app && adduser -u 10001 -S app -G app`.

```bash
$ docker compose build todo-insecure
$ ./scripts/run-trivy.sh image --severity HIGH,CRITICAL --format json \
      securitylabs/todo-insecure:latest | jq '[.Results[].Vulnerabilities // [] | length] | add // 0'
$ ./scripts/run-hadolint.sh insecure/Dockerfile
$ docker run --rm securitylabs/todo-insecure:latest id
$ ./scripts/run-trivy.sh image --scanners secret securitylabs/todo-insecure:latest
```

> ✅ Expected after all four: CVE count drops by roughly an order of magnitude, hadolint
> goes quiet, `id` reports a non-root uid, and the secret scanner finds nothing.
> Measured 2026-08-21 (Trivy 0.58.1, Hadolint 2.12.0):
>
> | metric                       | before  | after  |
> |------------------------------|---------|--------|
> | HIGH/CRITICAL CVEs           | 470     | 20     |
> | hadolint findings            | 4       | 0      |
> | image size                   | 1.84GB  | 209MB  |
> | `--scanners secret` findings | 3       | 0      |
> | `id`                         | `uid=0(root)` | `uid=10001(app)` |
>
> Attribute the steps honestly, because the result is not the intuitive one. Measured after
> each step:
>
> | after step                              | size   | HIGH/CRITICAL |
> |-----------------------------------------|--------|---------------|
> | (baseline)                              | 1.84GB | 470           |
> | 1. drop `curl python3 build-essential`  | 1.8GB  | **470**       |
> | 2. `node:latest` → `node:20-alpine`     | 209MB  | **20**        |
>
> **Deleting the extra packages removed exactly zero HIGH/CRITICAL CVEs.** Every one of the
> 470 was already in the Debian base image; `curl`, `python3` and `build-essential` added
> attack surface and ~40MB, but not a single scanner finding. The entire 470 → 20 drop is
> the one-word base image change. Steps 3 and 4 move different numbers — step 3 takes the
> secret findings from 3 to 0, step 4 changes `id` — and neither touches the CVE count.
>
> This is the most useful thing in the lab and the easiest to get backwards: "we removed
> unnecessary packages" is a real hardening win that your CVE dashboard will not reward,
> and "we changed one line of `FROM`" is the change that empties it.
>
> Note the floor too: 20 is the same HIGH/CRITICAL count `todo-secure` carries, and for the
> same reason — 18 of them are npm's own bundled dependencies inside `node:20-alpine`. You
> cannot patch those by editing your Dockerfile. Exercise 7 is how you get past them.
>
> ⚠️ Except it *will* still find the secret if you only edited the Dockerfile and rebuilt
> from cache — layers are immutable and the old image is still on your disk under its
> digest. `docker image prune` and re-pull, or better: understand that **you cannot remove a
> secret from a published image**. You rotate it. Same rule as lab 02.

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

### Image vulnerabilities vs runtime configuration

```text
   IMAGE (what you ship)                RUNTIME (how it is started)
   ─────────────────────                ───────────────────────────
   base image + packages                --user / runAsNonRoot
   your app + deps                      --cap-drop, --security-opt
   USER, ENV, HEALTHCHECK   ← defaults  --read-only, tmpfs, seccomp/AppArmor
   layers (immutable, forever)          network, mounts, /var/run/docker.sock
   ─────────────────────                ───────────────────────────
   measured by: trivy, syft, hadolint   measured by: docker inspect, PSS (lab 06),
                                        docker-bench §5, runtime policy engines
```

Trivy scanning an image cannot tell you the container will be launched `--privileged` with
the Docker socket mounted. Nothing in the image can prevent it. Both columns need a control,
and the right-hand one is the one that decides how bad a compromise gets.

### Why scanners hate `node:14`

```text
node:14   = node 14 (EOL) + Debian 11 + npm 6 + global packages
            ^^             ^^^^^^^^^^   ^^^^^   ^^^^^^^^^^^^^^^^
            CVEs           CVEs         CVEs    CVEs

node:20-alpine = node 20 + Alpine (musl, busybox) + npm
                          ^^^^^^^^^^^^^^^^^^^^^^^^   ^^^
                          few CVEs                   ALL the remaining CVEs
distroless     = node 20 + nothing else
```

The pattern repeats one level down. `node:20-alpine` measured 20 HIGH/CRITICAL in exercise
2 and **18 of them were npm's own bundled dependencies** in `/usr/local/lib/node_modules` —
Node 20 is EOL, so its shipped npm is frozen and its copies of `tar`, `minimatch` and
`brace-expansion` will never be patched. You do not run `npm` in production and you cannot
`apk upgrade` your way out of it. Shipping a package manager in a runtime image is the same
mistake as shipping `build-essential`, one layer up. That is the argument for distroless,
and it is worth more than the size argument people usually make.

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
- [cosign: signing with a key pair](https://docs.sigstore.dev/cosign/signing/signing_with_self-managed_keys/)

➡️ Next: [Lab 05 — Web App Security (OWASP Juice Shop + ZAP)](../05-web-app-security-owasp/)
