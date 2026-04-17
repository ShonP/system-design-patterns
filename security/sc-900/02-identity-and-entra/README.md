# Lab 2: Identity and Microsoft Entra

📖 **Exam domain**: Describe the capabilities of Microsoft Entra (25–30%)

This is the **highest-weighted** domain on the SC-900 exam. It covers identity concepts, Microsoft Entra ID (formerly Azure AD), authentication, access management, and identity governance.

## What you'll learn

- Identity as the security perimeter — authentication vs authorization
- Identity providers, directory services, and federation
- Microsoft Entra ID — identity types, hybrid identity
- Authentication methods — passwords, MFA, passwordless, SSPR
- Conditional Access policies and RBAC
- Identity governance — access reviews, PIM, ID Protection

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Identity fundamentals](notebooks/01_identity_fundamentals.ipynb) | Authn vs authz, IdPs, federation, directory services |
| 2 | [Entra ID and authentication](notebooks/02_entra_id_and_authentication.ipynb) | Entra ID, identity types, MFA, Conditional Access, RBAC |
| 3 | [Identity governance](notebooks/03_identity_governance.ipynb) | PIM, access reviews, ID Protection, entitlement management |

## Quick start

```bash
cd security/sc-900/02-identity-and-entra

# Start the mock Entra server (reuses the azure-authentication lab's mock)
docker compose up -d

uv sync
uv run python -m ipykernel install --user --name=sc-900 --display-name="SC-900 (Python)"
```

## Related

This lab builds on the [Azure Authentication lab](../../../enterprise-patterns/azure-authentication/) — if you want a deep dive into app registrations, service principals, client credentials, and On-Behalf-Of flows, go there after finishing this one.
