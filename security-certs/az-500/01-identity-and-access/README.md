# Lab 1: Secure Identity and Access

📖 **Exam domain**: Secure identity and access (15–20%)

## What you'll implement

- Azure built-in and custom RBAC roles
- PIM (Privileged Identity Management) settings and assignments
- MFA enforcement for Azure resources
- Conditional Access policies for cloud resources
- Enterprise app access and OAuth permission grants
- App registrations and permission scopes
- Service principals and managed identities

## Notebooks

| # | Notebook | Topics | Needs Docker? |
|---|----------|--------|:-:|
| 1 | [RBAC and custom roles](notebooks/01_rbac_and_custom_roles.ipynb) | Built-in roles, custom role creation, scopes, bad→best least privilege, Access Reviews, deny assignments | no |
| 2 | [PIM and Conditional Access](notebooks/02_pim_and_conditional_access.ipynb) | PIM eligible vs active, activation policies, CA structure, break-glass accounts, Identity Protection | no |
| 3 | [App registrations and managed identities](notebooks/03_app_registrations_and_managed_identities.ipynb) | App regs, delegated vs app tokens, consent, managed identities, Workload Identity Federation | **yes** |

## Quick start

```bash
cd security-certs/az-500/01-identity-and-access

# 1. Install Python dependencies into this lab's own .venv
uv sync

# 2. Start the tiny mock Entra ID (only needed for notebook 3)
docker compose up -d

# 3. Check the mock is healthy
curl http://localhost:9100/health
```

### Running the notebooks in VS Code

1. Open any notebook under `notebooks/`.
2. Click the **kernel picker** at the top-right of the notebook.
3. Choose the interpreter from this lab's `.venv` (managed by `uv`).
4. If the kernel doesn't appear, reload the VS Code window
   (`Cmd+Shift+P` → *Reload Window*).

### What the Docker mock is

`docker compose up -d` starts a minimal stand-in for Microsoft Entra ID (the real
`login.microsoftonline.com`) and a pretend protected API (`api-b`). They come
from the [`08-enterprise/azure-authentication`](../../../08-enterprise/azure-authentication)
lab and speak just enough OAuth2 so the notebooks can demonstrate tokens, scopes
and app roles without needing an Azure subscription.

When you are done:

```bash
docker compose down
```
