# Lab 3: Secure Compute, Storage, and Databases

📖 **Exam domain**: Secure compute, storage, and databases (20–25%)

## What you'll implement

- Bastion and JIT VM access (with a full NSG-rule lifecycle simulator)
- AKS security — private clusters, workload identity, network policy, Azure Policy add-on, ACR attach
- Container registry security — admission control, content trust, vulnerability scanning
- Disk encryption — SSE, ADE, encryption at host, confidential disk; Trusted Launch & Confidential VMs
- Storage access control — Entra RBAC, SAS (with live HMAC signing), stored access policies
- Storage network protection — firewall, private endpoints, "allow trusted Azure services"
- Storage encryption — BYOK (CMK), infrastructure encryption (double encryption)
- Storage data protection — soft delete, versioning, PITR, immutable storage (WORM)
- SQL security — Entra-only auth, firewall vs private endpoint, auditing, Defender for SQL
- Data protection — TDE (BYOK), Always Encrypted, Dynamic Data Masking, Row-Level Security
- Cosmos DB / PostgreSQL / MySQL security patterns
- Bad → best progression for every topic

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Compute security](notebooks/01_compute_security.ipynb) | Bastion, JIT, AKS, containers, disk encryption |
| 2 | [Storage security](notebooks/02_storage_security.ipynb) | Access control, SAS, BYOK, soft delete, immutable storage |
| 3 | [Database security](notebooks/03_database_security.ipynb) | SQL Entra auth, TDE, dynamic masking, Always Encrypted, auditing |

## Quick start

```bash
cd security/az-500/03-compute-storage-databases
uv sync
uv run python -m ipykernel install --user --name=az-500 --display-name="AZ-500 (Python)"
```
