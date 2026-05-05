# 🛡️ Security Labs — Learn Security By Doing

A hands-on, opinionated curriculum for learning **modern open-source security tooling**. Inspired by patterns described in `research-report.md` (a survey of the 2024–2025 OSS security ecosystem), each lab is a self-contained exercise with Docker-based setup, real vulnerabilities to find, and remediation steps.

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

| #  | Lab                                                              | Tools                                       | Time   |
|----|------------------------------------------------------------------|---------------------------------------------|--------|
| 01 | [Vulnerability Scanning](./01-vulnerability-scanning/)           | Trivy, Syft, Grype                          | 60 min |
| 02 | [Secrets Detection](./02-secrets-detection/)                     | Gitleaks, TruffleHog, pre-commit            | 45 min |
| 03 | [SAST / Code Scanning](./03-sast-code-scanning/)                 | Semgrep, Bandit                             | 75 min |
| 04 | [Container Security](./04-container-security/)                   | Docker, Trivy, Docker Bench, Hadolint       | 75 min |
| 05 | [Web App Security (OWASP)](./05-web-app-security-owasp/)         | Juice Shop, ZAP, Nuclei                     | 90 min |
| 06 | [Kubernetes Security](./06-kubernetes-security/)                 | Kubescape, Trivy Operator, kube-bench       | 90 min |
| 07 | [Infrastructure as Code](./07-infrastructure-as-code/)           | Checkov, KICS, tfsec, Prowler               | 75 min |
| 08 | [Incident Response](./08-incident-response/)                     | Wazuh, ELK, log analysis                    | 90 min |
| 09 | [Network Security](./09-network-security/)                       | Nmap, Nuclei, Wireshark/tshark              | 60 min |
| 10 | [Secure Development](./10-secure-development/)                   | Dependabot, Renovate, headers, rate limits  | 60 min |

Total: ~12 hours of hands-on work. Do them in order if you're new to security; jump around if you have a focus area.

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

**Beginner track** (4–6 hrs): 01 → 02 → 04 → 05
**Developer track** (6–8 hrs): 01 → 02 → 03 → 04 → 10
**DevSecOps track** (10+ hrs): 01 → 04 → 06 → 07 → 08 → 09
**AppSec track** (8–10 hrs): 01 → 02 → 03 → 05 → 10

---

## 🧰 Global Prerequisites

Install once, use everywhere:

```bash
# macOS
brew install docker docker-compose git curl jq
brew install --cask docker

# Linux (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install -y docker.io docker-compose git curl jq
sudo usermod -aG docker $USER  # log out + back in
```

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
- All labs are **self-contained**: run `docker compose down -v` when done to free disk space.
- **No production credentials.** Anything that looks like a key, token, or password in this repo is fake / planted on purpose.

---

## 🏗️ Repository Layout

```text
security-labs/
├── README.md                       # this file
├── research-report.md              # 2024–2025 OSS security tooling survey
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

## 🤝 Contributing / Forking

Fork freely. PRs that **add a new exercise**, **fix a broken scanner version**, or **add a new lab** are welcome. PRs that swap one tool for another for taste reasons probably are not — these labs are intentionally opinionated.

When a tool's CLI changes (and they do), please update the lab README and the script side-by-side.

---

## 📄 License

MIT — see [LICENSE](./LICENSE).

The vulnerable apps and intentionally-bad configs in this repo are derived from public OWASP / community projects and are clearly marked. **Don't deploy any of this to the internet.**
