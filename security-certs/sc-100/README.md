# SC-100: Microsoft Cybersecurity Architect Expert

📖 **Source**: [SC-100 Study Guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-100)

## What is SC-100?

SC-100 is an **expert-level** certification for cybersecurity architects. Unlike SC-200 (operate a SOC) or AZ-500 (configure security), SC-100 is about **designing** security architectures — choosing the right combination of services, mapping to frameworks, and making trade-off decisions.

This means the labs are different: instead of running commands, you'll work through **architecture design exercises** — threat modeling, framework mapping, reference architecture evaluation, and solution design patterns. Each notebook presents real-world scenarios and asks you to design the security solution.

## Exam domains → Labs

| Domain | Weight | Lab | What you'll design |
|--------|--------|-----|-------------------|
| Best practices & priorities | 20–25% | [01-best-practices](01-best-practices/) | Ransomware resiliency, Zero Trust adoption framework, MCRA/MCSB mapping, CAF/WAF alignment |
| SecOps, identity & compliance | 25–30% | [02-secops-identity-compliance](02-secops-identity-compliance/) | SIEM/XDR architecture, privileged access strategy, Conditional Access design, compliance controls |
| Infrastructure security | 25–30% | [03-infrastructure](03-infrastructure/) | Posture management, endpoint strategy, network security (SSE), hybrid/multicloud with Arc |
| Applications & data | 20–25% | [04-applications-and-data](04-applications-and-data/) | Threat modeling, DevSecOps, API security, data classification, encryption architecture |

## Prerequisites

- Completed SC-900 plus one of AZ-500 / SC-300 / SC-200 (one of those three is a hard prerequisite for the certification)
- Strong understanding of Azure services, Entra ID, Defender XDR, Sentinel, Purview
- Python 3.10+ for the interactive notebooks

## Quick start

```bash
cd security-certs/sc-100/<lab-folder>
uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```

No Docker needed — these labs are architecture design exercises, not service deployments.

## How SC-100 differs from other security certs

| | SC-900 | AZ-500 | SC-200 | SC-100 |
|-|--------|--------|--------|--------|
| Level | Fundamentals | Associate | Associate | **Expert** |
| Focus | "What is it?" | "Configure it" | "Operate it" | **"Design it"** |
| Question style | "Which service does X?" | "Which CLI command?" | "How to investigate?" | **"Which architecture?"** |
| Key skill | Recall | Implementation | Investigation | **Trade-off analysis** |

## Study tips

1. SC-100 is **heavily scenario-based** — every question gives a company description and asks you to design a solution.
2. Know the **frameworks** cold: Zero Trust, MCRA, MCSB, CAF, WAF, MITRE ATT&CK.
3. Know **which product fits which scenario** — don't memorize features, understand positioning.
4. Practice explaining **why** you'd pick one approach over another (trade-offs).
5. The certification has a **prerequisite**: you must already hold at least one of
   **Azure Security Engineer Associate (AZ-500)**, **Identity and Access Administrator Associate (SC-300)**, or
   **Security Operations Analyst Associate (SC-200)**. (MS-500 used to count but that certification is retired.)
6. Recent additions to the objectives worth extra study: **AI security** (securing AI workloads, Microsoft 365 Copilot
   data controls, AI in the MCSB), **Microsoft Entra Agent ID** for agent identities, **Microsoft Security Exposure
   Management** attack paths and initiatives, **Microsoft Purview Audit** in the centralized-logging objective, and the
   **Zero Trust adoption framework** (which replaced "RaMP" in Microsoft's wording).
