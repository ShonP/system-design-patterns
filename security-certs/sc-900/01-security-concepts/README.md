# Lab 1: Security, Compliance & Identity Concepts

📖 **Exam domain**: Describe the concepts of security, compliance, and identity (10–15%)

## What you'll learn

This lab covers the foundational mental models that every security topic builds on. After completing it you should be able to explain:

- **CIA triad** — confidentiality, integrity, availability, and which controls protect which leg
- **Shared responsibility model** — who secures what in IaaS / PaaS / SaaS
- **Defense in depth** — layered security (physical → network → application → data)
- **Zero Trust** — "never trust, always verify" (with a bad-vs-best castle-and-moat comparison)
- **Encryption & hashing** — symmetric vs asymmetric, hashing vs encryption, salting, digital signatures, hybrid encryption (TLS)
- **GRC** — governance, risk, and compliance frameworks

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Security models](notebooks/01_security_models.ipynb) | CIA triad, shared responsibility, defense in depth, Zero Trust (bad→best), GRC |
| 2 | [Encryption and hashing](notebooks/02_encryption_and_hashing.ipynb) | Symmetric/asymmetric encryption, hashing, salting (bad→best), digital signatures, TLS hybrid encryption |

## Quick start

```bash
cd security-certs/sc-900/01-security-concepts

uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```

No Docker needed — these labs are pure Python. Select the `.venv` kernel in VS Code (top-right of the notebook). If it doesn't appear, `Cmd+Shift+P` → **Developer: Reload Window**.
