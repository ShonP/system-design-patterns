# SC-100: Microsoft Cybersecurity Architect Expert

📖 **Source**: [SC-100 Study Guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-100)

## What is SC-100?

SC-100 is an **expert-level** certification for cybersecurity architects. Unlike SC-200 (operate a SOC) or AZ-500 (configure security), SC-100 is about **designing** security architectures — choosing the right combination of services, mapping to frameworks, and making trade-off decisions.

This means the labs are different: instead of running commands, you'll work through **architecture design exercises** — threat modeling, framework mapping, reference architecture evaluation, and solution design patterns. Each notebook presents real-world scenarios and asks you to design the security solution.

## Exam domains → Labs

| Domain | Weight | Lab | What you'll design |
|--------|--------|-----|-------------------|
| Best practices & priorities | 20–25% | [01-best-practices](01-best-practices/) | Ransomware resiliency, Zero Trust RaMP, MCRA/MCSB mapping, CAF/WAF alignment |
| SecOps, identity & compliance | 25–30% | [02-secops-identity-compliance](02-secops-identity-compliance/) | SIEM/XDR architecture, privileged access strategy, Conditional Access design, compliance controls |
| Infrastructure security | 25–30% | [03-infrastructure](03-infrastructure/) | Posture management, endpoint strategy, network security (SSE), hybrid/multicloud with Arc |
| Applications & data | 20–25% | [04-applications-and-data](04-applications-and-data/) | Threat modeling, DevSecOps, API security, data classification, encryption architecture |

## Prerequisites

- Completed SC-900, AZ-500, and SC-200 (or equivalent experience)
- Strong understanding of Azure services, Entra ID, Defender XDR, Sentinel, Purview
- Python 3.10+ for the interactive notebooks

## Quick start

```bash
cd security/sc-100/<lab-folder>
uv sync
uv run python -m ipykernel install --user --name=sc-100 --display-name="SC-100 (Python)"
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
5. The exam requires a prerequisite certification: SC-200, AZ-500, or MS-500.
