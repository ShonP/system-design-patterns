# Lab 3: Secure Compute, Storage, and Databases

📖 **Exam domain**: Secure compute, storage, and databases (20–25%)

## What you'll implement

- Bastion and JIT VM access
- AKS security — network policies, workload identity, ACR integration
- Container security — ACI, Container Apps, ACR
- Disk encryption — ADE, encryption at host, confidential disk
- Storage access control — SAS, access keys, RBAC, firewall rules
- Storage protection — soft delete, versioning, immutable storage, BYOK
- SQL security — Entra auth, auditing, dynamic masking, TDE, Always Encrypted

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
