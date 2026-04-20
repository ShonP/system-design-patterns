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
| 1 | [Identity fundamentals](notebooks/01_identity_fundamentals.ipynb) | Authn vs authz, IdPs, OAuth2/OIDC/SAML, JWT signature validation, federation |
| 2 | [Entra ID and authentication](notebooks/02_entra_id_and_authentication.ipynb) | Identity types (app registrations, SPs, managed identities), MFA, Conditional Access bad→best, RBAC |
| 3 | [Identity governance](notebooks/03_identity_governance.ipynb) | PIM (standing vs JIT admin), access reviews, ID Protection, entitlement management |

## Quick start

```bash
cd security-certs/sc-900/02-identity-and-entra

# Start the mock Entra server (reuses the azure-authentication lab's mock)
docker compose up -d

uv sync
uv run python -m ipykernel install --user --name=sc-900 --display-name="SC-900 (Python)"
```

In each notebook, select the `SC-900 (Python)` kernel (top-right kernel picker in VS Code). If it does not appear, reload the window (`Cmd+Shift+P` → *Reload Window*).

## Related

This lab builds on the [Azure Authentication lab](../../../08-enterprise/azure-authentication/) — if you want a deep dive into app registrations, service principals, client credentials, and On-Behalf-Of flows, go there after finishing this one.
