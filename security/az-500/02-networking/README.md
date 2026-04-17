# Lab 2: Secure Networking

📖 **Exam domain**: Secure networking (20–25%)

## What you'll implement

- NSGs and Application Security Groups (ASGs)
- User-defined routes (UDRs)
- VNet peering and VPN gateways
- Service Endpoints and Private Endpoints
- Private Link services
- App Service VNet integration
- Azure Firewall and firewall policies
- Application Gateway and WAF
- Azure Front Door with CDN
- DDoS Protection Standard
- Network Watcher monitoring

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [NSGs, ASGs, and routing](notebooks/01_nsgs_asgs_and_routing.ipynb) | NSG rules, ASGs, UDRs, forced tunneling, Network Watcher |
| 2 | [Private access](notebooks/02_private_access.ipynb) | Service Endpoints, Private Endpoints, Private Link, App Service VNet integration |
| 3 | [Public access and firewalls](notebooks/03_public_access_and_firewalls.ipynb) | Azure Firewall, App Gateway + WAF, Front Door, DDoS Protection |

## Quick start

```bash
cd security/az-500/02-networking
uv sync
uv run python -m ipykernel install --user --name=az-500 --display-name="AZ-500 (Python)"
```
