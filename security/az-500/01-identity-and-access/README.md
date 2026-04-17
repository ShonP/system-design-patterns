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

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [RBAC and custom roles](notebooks/01_rbac_and_custom_roles.ipynb) | Built-in roles, custom role creation, role assignment scopes, deny assignments |
| 2 | [PIM and Conditional Access](notebooks/02_pim_and_conditional_access.ipynb) | PIM eligible vs active, activation policies, Conditional Access implementation |
| 3 | [App registrations and managed identities](notebooks/03_app_registrations_and_managed_identities.ipynb) | App regs, service principals, OAuth scopes, managed identity types and usage |

## Quick start

```bash
cd security/az-500/01-identity-and-access
docker compose up -d
uv sync
uv run python -m ipykernel install --user --name=az-500 --display-name="AZ-500 (Python)"
```
