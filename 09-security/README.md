# 🛡️ Security Labs — Learn Security By Doing

A hands-on, opinionated curriculum for learning **modern open-source security tooling**. Each lab is self-contained: Docker-based setup, real vulnerabilities to find, and — this is the part most tutorials skip — a remediation step and a rescan that proves the fix worked.

> **You don't learn security by reading.** You learn it by scanning a vulnerable image, getting a wall of CVEs, fixing them, and rescanning until the wall shrinks. These labs are designed for that loop.

---

## 🎯 Who is this for?

- Engineers who want to understand security tools beyond "I read about Trivy once"
- Developers being asked to own security in their CI/CD
- Aspiring AppSec / DevSecOps / Cloud Security folks who need a portfolio of actual experience
- People who learned syntax from courses and now want **muscle memory**

Prerequisites: comfort with Docker, a terminal, and Git. Each lab spells out language-specific prerequisites where needed.

---

## 📚 Syllabus

| #  | Lab                                                              | Tools                                              | Exercises | Time    |
|----|------------------------------------------------------------------|----------------------------------------------------|-----------|---------|
| 01 | [Vulnerability Scanning](./01-vulnerability-scanning/)           | Trivy, Syft, Grype, CISA KEV                        | 8         | 75 min  |
| 02 | [Secrets Detection](./02-secrets-detection/)                     | Gitleaks, TruffleHog, pre-commit                    | 8         | 60 min  |
| 03 | [SAST / Code Scanning](./03-sast-code-scanning/)                 | Semgrep (+ taint mode), Bandit                      | 9         | 90 min  |
| 04 | [Container Security](./04-container-security/)                   | Hadolint, Trivy, Syft, Docker Bench, cosign         | 9         | 90 min  |
| 05 | [Web App Security (OWASP)](./05-web-app-security-owasp/)         | Juice Shop, ZAP (baseline/full/proxy), Nuclei       | 9         | 120 min |
| 06 | [Kubernetes Security](./06-kubernetes-security/)                 | kind, Kubescape, Trivy Operator, kube-bench, Calico | 9         | 120 min |
| 07 | [Infrastructure as Code](./07-infrastructure-as-code/)           | Checkov, KICS, tfsec, Trivy, Prowler                | 7         | 75 min  |
| 08 | [Incident Response](./08-incident-response/)                     | Wazuh (manager/indexer/dashboard), Sigma            | 8         | 120 min |
| 09 | [Network Security](./09-network-security/)                       | Nmap + NSE, Nuclei, tshark, iptables                | 9         | 75 min  |
| 10 | [Secure Development](./10-secure-development/)                   | helmet, zod, rate limits, Dependabot, Renovate      | 10        | 90 min  |

Total: **~15–16 hours** of hands-on work, plus image pulls. Labs 05, 06 and 08 are the
long ones — 05 because a full ZAP active scan takes 10–30 minutes on its own, 06 because
exercise 5 requires rebuilding the cluster with a different CNI, and 08 because Wazuh is
three services that take minutes to become healthy. Do them in order if you're new to
security; jump around if you have a focus area.

---

## 🗺️ Learning Path

```text
                ┌─────────────────────────────────┐
                │  01 Vulnerability Scanning      │  ← Start here. SBOM-first thinking.
                └───────────────┬─────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
  02 Secrets             03 SAST                  04 Containers
  (Gitleaks)             (Semgrep)                (Trivy + Docker)
        │                       │                       │
        └───────────┬───────────┴───────────┬───────────┘
                    ▼                       ▼
             05 Web (OWASP)           07 IaC (Checkov)
                    │                       │
                    ▼                       ▼
             06 Kubernetes            10 Secure Dev
                    │                       │
                    ▼                       ▼
             08 Incident Response ←→ 09 Network
```

**Beginner track** (~6 hrs): 01 → 02 → 04 → 05
**Developer track** (~7 hrs): 01 → 02 → 03 → 04 → 10
**DevSecOps track** (~8.5 hrs): 01 → 04 → 06 → 07 → 08 → 09
**AppSec track** (~7 hrs): 01 → 02 → 03 → 05 → 10

---

## 🧰 Global Prerequisites

Install once, use everywhere:

```bash
# macOS
brew install --cask docker         # Docker Desktop (includes the compose plugin)
brew install git curl jq

# Linux (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install -y docker.io docker-compose-plugin git curl jq
sudo usermod -aG docker $USER  # log out + back in
```

Per-lab extras (each lab's Prerequisites section repeats this):

| Lab | Also needs |
|-----|------------|
| 06  | `kubectl`, `kind`, `helm` (`brew install kubectl kind helm`) — and ~3 GB RAM for the cluster |
| 08  | ≥ 6 GB of RAM allocated to Docker; on Linux, `sudo sysctl -w vm.max_map_count=262144` |
| 10  | Node 20 if you want to run the apps outside Docker |
| 02, 03, 04, 07 | Optional native CLIs (`gitleaks`, `semgrep`, `bandit`, `hadolint`, `checkov`, `trivy`, `cosign`) — every wrapper script prefers a native binary and falls back to Docker |

Most labs run scanners as **Docker containers** so you don't have to install 15 different CLIs locally. Where a native install is significantly easier (e.g., `trivy` via Homebrew), the lab will mention it.

Verify:

```bash
docker --version
docker compose version
git --version
```

---

## 🧪 Lab Anatomy

Every lab folder follows the same structure:

```text
NN-lab-name/
├── README.md              # 🎯 learn / 📋 prereqs / 🔧 setup / 📝 exercises / 💡 concepts / 🏆 challenge / 📚 further reading
├── docker-compose.yml     # spins up the targets and/or scanners
├── scripts/               # helper scripts you run during exercises
├── exercises/             # exercise-specific files: vulnerable code, configs, expected outputs
└── (lab-specific dirs)    # e.g., terraform-bad/, vulnerable-app/, manifests/
```

Each README's `📝 Exercises` section is **numbered, copy-pastable, and verifiable**. You should always be able to tell whether you got the right answer.

---

## 🧠 Mental Model: How Modern Security Tooling Fits Together

```text
       ┌──────────────────────────────────────────────────────┐
       │                  YOUR ARTIFACTS                      │
       │   source code · Dockerfiles · IaC · K8s · cloud      │
       └──────────────────────┬───────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
   SBOM/Inventory       Static Analysis        Dynamic Analysis
   (Syft, Trivy)        (Semgrep, Bandit,      (ZAP, Nuclei,
                         Gitleaks, Checkov)     Nmap)
        │                     │                     │
        └──────────┬──────────┴──────────┬──────────┘
                   ▼                     ▼
            Vuln Matching          Posture / Compliance
            (Grype, Trivy,         (Prowler, Kubescape,
             OSV-Scanner)           kube-bench)
                   │                     │
                   └──────────┬──────────┘
                              ▼
                    Aggregation & Triage
                    (DefectDojo, Dependency-Track)
                              │
                              ▼
                  Risk-prioritized findings
                 (CVSS + KEV + EPSS + context)
```

You'll touch most of this graph by the time you finish Lab 10.

---

## 🚦 Conventions

- **`$` prefix** = run on your host shell
- **`#` prefix** = run inside a container (root)
- Sample outputs are abbreviated. Your CVE counts will differ as databases are updated daily — that's normal.
- **Port conflicts are the #1 setup failure.** Lab 05 wants 3000 (override with `JUICE_PORT`),
  lab 08 wants 8443/9200/1514/1515/55000, lab 10 wants 3001/3002, lab 04 exercise 8 wants 5001.
  If a `docker compose up` dies on "address already in use", change the host-side port; nothing
  in these labs depends on a specific one.
- Each lab writes scanner output into its own `exercises/` directory. Those files are
  gitignored and regenerated on every run — but several exercises **read the output of an
  earlier exercise**, so skipping around inside a lab will produce `null` from `jq`. Each
  README flags the dependency where it exists.
- All labs are **self-contained**: run `docker compose down -v` when done to free disk space.
- **No production credentials.** Anything that looks like a key, token, or password in this repo is fake / planted on purpose.

---

## 🏗️ Repository Layout

```text
09-security/
├── README.md                       # this file
├── 01-vulnerability-scanning/
├── 02-secrets-detection/
├── 03-sast-code-scanning/
├── 04-container-security/
├── 05-web-app-security-owasp/
├── 06-kubernetes-security/
├── 07-infrastructure-as-code/
├── 08-incident-response/
├── 09-network-security/
└── 10-secure-development/
```

---

## 🧭 Tool versions, drift, and what "expected output" means here

Every scanner image is pinned (`aquasec/trivy:0.58.1`, `zricethezav/gitleaks:v8.21.2`,
`semgrep/semgrep:1.96.0`, …) so that a lab you run today behaves like the lab that was
written. Two consequences you should expect:

- **Pinned tags age out.** If a `docker pull` 404s, the tag was removed upstream — bump it
  in the wrapper script and the compose file together, and expect the exercise's expected
  output to shift a little.
- **The wrappers prefer your native binary over the pinned image.** That is deliberate (it
  is much faster), but it means you may be running a newer tool than the lab was written
  against. Gitleaks is the sharpest example: the `detect` command that every older tutorial
  uses no longer exists in 8.3x. Where a version difference changes the *commands*, not just
  the counts, the lab README says so.

### Where the "expected output" numbers come from

| Claim | Status |
|---|---|
| Lab 02 finding counts (4 in the tree, 7 across 4 commits, 5 with the custom rule), and the fact that the AWS documentation canary is *not* reported | **Measured** — gitleaks 8.30.1, default config |
| Lab 07 checkov counts (52 failed on `terraform-bad/`, 0 failed + 4 skipped on `terraform-good/`, custom policy FAIL→PASS) | **Measured** — checkov 3.2.x |
| Every YAML / JSON / TOML / XML / Python / shell file in this section parses | **Measured** |
| Everything requiring a container to run — CVE counts, ZAP alert lists, Wazuh alerts, kube-bench output, nuclei hits, cosign signatures | **Not measured.** These are stated as shapes and orders of magnitude, and they drift with vulnerability databases and rule packs anyway. If your numbers differ, that is expected; if the *commands* fail, that is a bug worth a PR. |
| Pinned image tags exist upstream | **Not verified.** They were correct when written; see the drift note above. |

Treat every expected count as "the right order of magnitude and the right shape", never as
a test to pass.

## 🤝 Contributing / Forking

Fork freely. PRs that **add a new exercise**, **fix a broken scanner version**, or **add a new lab** are welcome. PRs that swap one tool for another for taste reasons probably are not — these labs are intentionally opinionated.

When a tool's CLI changes (and they do), please update the lab README and the script side-by-side.

---

## 📄 License

MIT — see [LICENSE](../LICENSE).

The vulnerable apps and intentionally-bad configs in this repo are derived from public OWASP / community projects and are clearly marked. **Don't deploy any of this to the internet.**
