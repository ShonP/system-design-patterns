# Lab 2: Identity and Microsoft Entra

📖 **Exam domain**: Describe the capabilities of Microsoft Entra (25–30%)

This is the **highest-weighted** domain on the SC-900 exam. It covers identity concepts, Microsoft Entra ID (formerly Azure AD), authentication, access management, and identity governance.

## What you'll learn

- Identity as the security perimeter — authentication vs authorization (401 vs 403)
- Identity providers, directory services, federation vs synchronisation vs cloud-only
- Microsoft Entra ID — identity types (including **agent ID**), hybrid identity
- Authentication methods ranked by strength — and why *MFA* and *phishing-resistant* are
  two different claims (SMS is the weak one; passkeys, Windows Hello and CBA are the strong ones)
- Password protection — SSPR, global and custom banned password lists
- Conditional Access, the three Zero Trust principles, and RBAC
- Identity governance — access reviews, PIM, entitlement management, ID Protection

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Identity fundamentals](notebooks/01_identity_fundamentals.ipynb) | Authn vs authz (a real 401 *and* a real 403), the four pillars, IdPs, OAuth2/OIDC/SAML, JWT signature validation, federation vs sync vs cloud-only |
| 2 | [Entra ID and authentication](notebooks/02_entra_id_and_authentication.ipynb) | Identity types (app registrations, SPs, managed identities, agent ID), authentication-method strength, MFA vs phishing-resistance, password protection, Conditional Access bad→best, Zero Trust, RBAC |
| 3 | [Identity governance](notebooks/03_identity_governance.ipynb) | PIM (standing vs JIT admin), access reviews, ID Protection, entitlement management, lifecycle workflows |

Each notebook ends with a **self-check** quiz — edit `MY_ANSWERS`, re-run, and read the
explanation for anything you missed.

## Quick start

```bash
cd security-certs/sc-900/02-identity-and-entra

# Start the mock Entra server (reuses the azure-authentication lab's mock)
docker compose up -d --build

uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```

In each notebook, select the `SC-900 (Python)` kernel (top-right kernel picker in VS Code). If it does not appear, reload the window (`Cmd+Shift+P` → *Reload Window*).

## Related

This lab builds on the [Azure Authentication lab](../../../08-enterprise/azure-authentication/) — if you want a deep dive into app registrations, service principals, client credentials, and On-Behalf-Of flows, go there after finishing this one.
