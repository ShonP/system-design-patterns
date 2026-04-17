# AZ-500: Microsoft Azure Security Technologies

📖 **Source**: [AZ-500 Study Guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-500)

## What is AZ-500?

AZ-500 is an associate-level certification for **Azure Security Engineers**. Unlike the foundational SC-900 (concepts), AZ-500 is about **implementing** security — configuring NSGs, writing Azure Policy, deploying Defender for Cloud plans, building Sentinel analytics rules, managing Key Vault, securing AKS, and more.

This lab series covers every exam domain with runnable code, real Azure CLI commands, and interactive simulations so you can practice without needing a live Azure subscription for most exercises.

> **Note**: This exam retires August 31, 2026. Microsoft is consolidating into newer certifications, but the skills are evergreen.

## Exam domains → Labs

| Domain | Weight | Lab | What you'll implement |
|--------|--------|-----|----------------------|
| Secure identity and access | 15–20% | [01-identity-and-access](01-identity-and-access/) | RBAC, custom roles, PIM, MFA, Conditional Access, app registrations, managed identities |
| Secure networking | 20–25% | [02-networking](02-networking/) | NSGs, ASGs, UDRs, VNet peering, Private Endpoints, Azure Firewall, WAF, DDoS |
| Secure compute, storage, databases | 20–25% | [03-compute-storage-databases](03-compute-storage-databases/) | Bastion, JIT, AKS security, ACR, disk encryption, storage access, SQL TDE, dynamic masking |
| Defender for Cloud & Sentinel | 30–35% | [04-defender-and-sentinel](04-defender-and-sentinel/) | Azure Policy, Key Vault, Secure Score, Defender plans, Sentinel data connectors, analytics rules, automation |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (required for most labs — many exercises use `az` commands)
- An Azure subscription (free tier works for most labs)
- Completed [SC-900 labs](../sc-900/) or equivalent knowledge

## Quick start (any lab)

```bash
cd security/az-500/<lab-folder>

# Start any needed infrastructure
docker compose up -d    # (only if the lab has a docker-compose.yml)

# Install dependencies + register kernel
uv sync
uv run python -m ipykernel install --user --name=az-500 --display-name="AZ-500 (Python)"
```

Select the `AZ-500 (Python)` kernel. If it doesn't appear, `Cmd+Shift+P` → **Reload Window**.

## How these labs differ from SC-900

| | SC-900 | AZ-500 |
|-|--------|--------|
| Level | Foundational (concepts) | Associate (implementation) |
| Focus | "What is it?" | "How do I configure it?" |
| Azure CLI | Optional | Required |
| Hands-on | Simulations | Real Azure + simulations |
| Code | Python demos | Python + Azure CLI + Bicep/ARM |

## Study tips

1. **Do SC-900 first** if the concepts feel unfamiliar.
2. **Use a free Azure subscription** — most labs cost under $5/month with cleanup.
3. **Run the cleanup scripts** after each lab to avoid surprise charges.
4. Each notebook starts with simulation code then shows the real Azure CLI equivalents.
5. The exam is **heavily scenario-based** — practice *deciding which tool to use*, not just configuring.
