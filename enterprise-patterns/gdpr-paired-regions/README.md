# GDPR Compliance & Azure Paired Regions

📖 **Pattern Source**: [Microsoft Azure — Paired Regions](https://learn.microsoft.com/en-us/azure/reliability/cross-region-replication-azure)

## Overview

The **General Data Protection Regulation (GDPR)** is a European Union law that controls how companies collect, store, and process personal data of EU citizens. It came into effect on May 25, 2018, and applies to **any** company that handles EU citizen data — even if the company is based outside the EU.

Microsoft Azure solves the hardest GDPR challenge — **keeping data inside the EU while still having disaster recovery** — through a concept called **Paired Regions**. Each Azure region is paired with another region in the **same geography** (e.g., West Europe 🇳🇱 is paired with North Europe 🇮🇪). Data never leaves the geography, even during failovers.

This lab teaches you:
- What GDPR requires and why it matters
- How paired regions keep data within legal boundaries
- How to implement the "right to be forgotten" (Article 17)
- How to audit data residency for compliance reports

## What is GDPR?

GDPR is built around these key principles:

| Principle | What It Means | Example |
|-----------|---------------|---------|
| **Lawfulness** | You need a legal reason to process data | User gave consent, or you need it for a contract |
| **Purpose Limitation** | Only use data for stated purposes | Collected email for shipping → can't sell it to advertisers |
| **Data Minimization** | Only collect what you need | Don't ask for date-of-birth if you don't need it |
| **Storage Limitation** | Don't keep data longer than necessary | Delete accounts inactive for 3 years |
| **Integrity** | Keep data accurate and secure | Encrypt PII, use access controls |
| **Accountability** | Prove you're compliant | Audit logs, consent records, data maps |

### Key Rights of EU Citizens

1. **Right to Access** (Article 15) — "Show me all data you have on me"
2. **Right to Rectification** (Article 16) — "Fix my incorrect data"
3. **Right to Erasure** (Article 17) — "Delete all my data" (right to be forgotten)
4. **Right to Portability** (Article 20) — "Give me my data in a machine-readable format"
5. **Right to Object** (Article 21) — "Stop processing my data for marketing"

### What Happens If You Don't Comply?

Fines up to **€20 million** or **4% of global annual revenue** (whichever is higher). In 2023, Meta was fined **€1.2 billion** for transferring EU data to the US.

## Why Azure Paired Regions Matter for GDPR

### The Problem

GDPR requires that EU citizen data stays within the EU (or in countries with equivalent data protection). But you also need:
- **Disaster recovery** — if a data center floods, your data must survive
- **High availability** — users expect near-zero downtime
- **Backups** — stored in a different physical location

### The Solution: Paired Regions

Azure pairs regions **within the same geography**:

| Primary Region | Paired Region | Geography |
|---------------|---------------|-----------|
| West Europe (Netherlands 🇳🇱) | North Europe (Ireland 🇮🇪) | Europe |
| France Central (Paris 🇫🇷) | France South (Marseille 🇫🇷) | France |
| Germany West Central (Frankfurt 🇩🇪) | Germany North (Berlin 🇩🇪) | Germany |
| UK South (London 🇬🇧) | UK West (Cardiff 🇬🇧) | United Kingdom |

**Key guarantee**: Data replicated between paired regions **never leaves the geography**. A Dutch user's data goes Netherlands → Ireland, never to the US.

### How It Works

```
EU Citizen (Netherlands)
        │
        ▼
┌─────────────────┐     async replication     ┌─────────────────┐
│   EU-West       │ ─────────────────────────► │   EU-North      │
│   (Netherlands) │                            │   (Ireland)     │
│   PRIMARY       │ ◄───────── failover ────── │   SECONDARY     │
│                 │                            │                 │
│  • User data    │                            │  • Replica data │
│  • Orders       │                            │  • DR backup    │
│  • Consent logs │                            │  • Read replica │
└─────────────────┘                            └─────────────────┘
        │                                              │
        └──────────── Both inside EU ──────────────────┘
```

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Data Residency Basics | Storing PII in the correct region, geo-routing writes |
| 2 | Cross-Region Replication | Async replication between paired regions, failover |
| 3 | Right to Erasure | Implementing GDPR Article 17 with cascading deletes |
| 4 | Data Sovereignty Audit | Auditing where data lives, generating compliance reports |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd enterprise-patterns/gdpr-paired-regions

# Start both region databases + Adminer
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=gdpr-paired-regions --display-name="GDPR Paired Regions (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8081
- **EU-West DB**: System `PostgreSQL`, Server `postgres-eu-west`, Username `demo`, Password `demo`, Database `gdpr_eu_west`
- **EU-North DB**: System `PostgreSQL`, Server `postgres-eu-north`, Username `demo`, Password `demo`, Database `gdpr_eu_north`
- **Use for**: Compare data across regions, watch replication, verify erasure

> 💡 **Tip**: Open two Adminer tabs — one connected to each region — to see data side-by-side.

## Architecture of This Lab

```
┌──────────────────────────────────────────────────────────┐
│                    Your Laptop                           │
│                                                          │
│  ┌─────────────┐    ┌──────────────┐  ┌──────────────┐  │
│  │  Jupyter     │    │ postgres     │  │ postgres     │  │
│  │  Notebooks   │───►│ eu-west      │  │ eu-north     │  │
│  │  (Python)    │───►│ :5433        │  │ :5434        │  │
│  └─────────────┘    └──────────────┘  └──────────────┘  │
│                           │                   │          │
│                     ┌─────┴───────────────────┘          │
│                     ▼                                    │
│              ┌──────────────┐                            │
│              │   Adminer    │                            │
│              │   :8081      │                            │
│              └──────────────┘                            │
└──────────────────────────────────────────────────────────┘
```

Both Postgres instances start with the **same schema and seed data**. The notebooks then demonstrate how a real system would route writes to the correct region and replicate across the pair.

## Real-World Examples

| Company | GDPR Challenge | How Paired Regions Help |
|---------|---------------|------------------------|
| **Microsoft** | Azure serves millions of EU customers | Paired regions keep data in-geography |
| **Spotify** | Swedish company, EU users worldwide | Stockholm + Ireland pairing |
| **SAP** | German enterprise data sovereignty laws | Frankfurt + Berlin pairing |
| **Stripe** | Payment data for EU merchants | Must keep financial PII in EU |

## Further Reading

- [GDPR Full Text](https://gdpr-info.eu/)
- [Azure Paired Regions Documentation](https://learn.microsoft.com/en-us/azure/reliability/cross-region-replication-azure)
- [Microsoft GDPR Compliance](https://learn.microsoft.com/en-us/compliance/regulatory/gdpr)
- [Azure Data Residency](https://azure.microsoft.com/en-us/explore/global-infrastructure/data-residency/)

## License

Educational content — feel free to use and modify for learning purposes.
