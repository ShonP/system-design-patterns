# Lab 2: Incident Response

📖 **Exam domain**: Respond to security incidents (35–40%)

## What you'll practice

Using the mini-SIEM from Lab 1, you'll work through realistic incident response scenarios across Defender XDR, Defender for Endpoint, and Sentinel.

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [Multi-stage attack investigation](notebooks/01_multi_stage_attack.ipynb) | Investigate a full kill-chain attack across multiple data sources |
| 2 | [Defender XDR incident response](notebooks/02_defender_xdr_response.ipynb) | Office 365, Entra ID, Endpoint, Cloud Apps response procedures |

## Quick start

```bash
cd security/sc-200/02-incident-response
# Uses the same SIEM from Lab 1 — make sure it's running:
# cd ../01-build-a-siem && docker compose up -d
uv sync
uv run python -m ipykernel install --user --name=sc-200 --display-name="SC-200 (Python)"
```
