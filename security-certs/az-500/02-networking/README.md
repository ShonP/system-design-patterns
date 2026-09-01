# Lab 2: Secure Networking

📖 **Exam domain**: Secure networking (20–25%)

## What you'll implement

- NSGs and Application Security Groups (ASGs)
- User-defined routes (UDRs)
- VNet peering and VPN gateways
- Service Endpoints and Private Endpoints
- Private Link services
- App Service VNet integration
- Azure Bastion sourcing for NSG rules (full Bastion deep dive lives in Lab 3)
- Azure Firewall and firewall policies
- Application Gateway and WAF
- Azure Front Door with CDN
- DDoS protection tiers (Network Protection / IP Protection / free infrastructure protection)
- Network Watcher monitoring

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [NSGs, ASGs, and routing](notebooks/01_nsgs_asgs_and_routing.ipynb) | NSG default rules & priority order, ASGs, UDRs, forced tunneling, Network Watcher IP flow verify, bad→best NSG progression, self-check |
| 2 | [Private access](notebooks/02_private_access.ipynb) | Service Endpoints vs Private Endpoints, Private Link, App Service VNet integration, non-transitive VNet peering, VPN gateway, privatelink DNS resolution, self-check |
| 3 | [Public access and firewalls](notebooks/03_public_access_and_firewalls.ipynb) | Azure Firewall SKUs & rule order, App Gateway + WAF (with a toy OWASP WAF), Front Door, DDoS tiers, defense-in-depth pipeline, self-check |

## Quick start

```bash
cd security-certs/az-500/02-networking
uv sync
# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/
```
