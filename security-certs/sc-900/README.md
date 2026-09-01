# SC-900: Microsoft Security, Compliance, and Identity Fundamentals

📖 **Source**: [Microsoft SC-900 Study Guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-900)

## What is SC-900?

SC-900 is a foundational certification that covers security, compliance, and identity (SCI) across Microsoft cloud services. It's beginner-level — no Azure experience required — but understanding these concepts is critical for *anyone* building cloud systems.

This lab series teaches every SC-900 domain through **runnable code and real examples**. Instead of reading slides about "what is encryption?", you'll encrypt data, crack weak hashes, build Zero Trust checks, deploy NSGs, and query security logs — all hands-on.

## Exam domains → Labs

The exam has 4 domains. Each maps to a lab folder:

| Domain | Weight | Lab | What you'll do |
|--------|--------|-----|----------------|
| Security, compliance & identity concepts | 10–15% | [01-security-concepts](01-security-concepts/) | Encrypt data, hash passwords, see why salting matters, model Zero Trust and defense-in-depth |
| Microsoft Entra capabilities | 25–30% | [02-identity-and-entra](02-identity-and-entra/) | Build auth flows, see MFA in action, create Conditional Access policies, explore RBAC |
| Microsoft security solutions | 35–40% | [03-azure-security-solutions](03-azure-security-solutions/) | Deploy NSGs & VNets, use Key Vault, write Sentinel KQL queries, explore Defender for Cloud |
| Microsoft compliance solutions | 20–25% | [04-compliance-and-purview](04-compliance-and-purview/) | Build DLP pattern matchers, classify sensitive data, model retention policies, explore eDiscovery |

## Prerequisites

- Python 3.10+
- No Docker required — every SC-900 lab here is pure Python
- Optional: [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) + a free Azure subscription for the Azure-specific labs

## Quick start (any lab)

```bash
cd security-certs/sc-900/<lab-folder>

# Install dependencies + register kernel
uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```

Then open any notebook and select the `SC-900 (Python)` kernel. If it doesn't appear, `Cmd+Shift+P` → **Reload Window**.

## Lab structure

Each lab folder contains:

```
<lab>/
├── README.md            # Overview and learning objectives
├── pyproject.toml       # Python dependencies
├── notebooks/           # Interactive Jupyter notebooks (numbered)
└── scripts/             # Azure CLI scripts for real-Azure exercises (optional)
```

## Study tips

1. **Do the labs in order** — concepts build on each other (encryption → identity → security services → compliance).
2. **Run every cell** — reading about hashing teaches you nothing; *watching a hash collision* teaches you everything.
3. **Take the practice assessment** after finishing all 4 labs: [SC-900 Practice Assessment](https://learn.microsoft.com/en-us/credentials/certifications/security-compliance-and-identity-fundamentals/practice/assessment?assessment-type=practice&assessmentId=11&practice-assessment-type=certification).
4. Labs 3 and 4 include optional Azure CLI scripts for real-tenant exercises — use a free Azure subscription.

## Related labs in this repo

- [Azure Authentication](../../08-enterprise/azure-authentication/) — deep dive on app registrations, service principals, managed identities, On-Behalf-Of flow (goes beyond SC-900 into real implementation)
