# GDPR Compliance & Azure Paired Regions

📖 **Pattern Source**: [Microsoft Azure — Region pairs and nonpaired regions](https://learn.microsoft.com/en-us/azure/reliability/regions-paired)

## Overview

The **General Data Protection Regulation (GDPR)** is a European Union law that controls how organisations collect, store, and process personal data. It came into effect on May 25, 2018.

> ⚖️ **Who it protects — a detail almost every tutorial gets wrong.** GDPR does **not** protect "EU citizens". Article 3 ties the regulation to *data subjects who are in the Union*, whatever their nationality, and to controllers/processors established in the Union. A US citizen living in Berlin is protected; an Irish citizen living in Tokyo, using a service with no EU establishment and no EU targeting, generally is not. This lab says **data subject** where it means the person the data is about.

> ⚖️ **GDPR is not a data-localisation law.** There is no article that says "EU personal data must stay in the EU". What GDPR does is restrict *transfers to third countries*: Chapter V (Articles 44–50) says you may only transfer personal data outside the EU/EEA if there is an adequacy decision, appropriate safeguards (Standard Contractual Clauses, Binding Corporate Rules), or a derogation — and, after *Schrems II*, only if a transfer impact assessment shows the destination's law does not undermine those safeguards. Keeping data in-region is a popular *engineering strategy* for reducing that burden, and is sometimes required by sector-specific or national law, but it is a design choice, not a GDPR requirement in itself.

Azure's **Paired Regions** are one building block for that strategy: some Azure services replicate to a designated partner region, and Microsoft states that *almost all* regions sit in the same geography as their pair. The caveats matter, and are spelled out below.

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

### Key Rights of Data Subjects

1. **Right to Access** (Article 15) — "Show me all data you have on me"
2. **Right to Rectification** (Article 16) — "Fix my incorrect data"
3. **Right to Erasure** (Article 17) — "Delete all my data" (right to be forgotten)
4. **Right to Portability** (Article 20) — "Give me my data in a machine-readable format"
5. **Right to Object** (Article 21) — "Stop processing my data for marketing"

### What Happens If You Don't Comply?

For the most serious infringements, Article 83(5) allows fines up to **€20 million** or **4% of total worldwide annual turnover**, whichever is higher (a lower €10m / 2% tier applies to other infringements). In May 2023 the Irish DPC fined Meta **€1.2 billion** over transfers of EU user data to the US under Standard Contractual Clauses that, post-*Schrems II*, could not compensate for US surveillance law. Note what that case was actually about: **the legal basis for the transfer**, not the absence of an EU data centre.

## Why Azure Paired Regions Matter for GDPR

### The Problem

Suppose you have decided — for Chapter V reasons, for a customer contract, or because a national regulator told you to — that a given dataset will stay inside the EU/EEA. You still need:
- **Disaster recovery** — if a data center floods, your data must survive
- **High availability** — users expect near-zero downtime
- **Backups** — stored in a different physical location

Each of those puts a *second copy* of the data somewhere. The engineering problem is making sure that second somewhere is inside the boundary you committed to.

### The Solution: Paired Regions

Microsoft associates *some* Azure regions with a partner region. European pairs, as documented by Microsoft:

| Primary Region | Paired Region | Geography |
|---------------|---------------|-----------|
| West Europe (Netherlands 🇳🇱) | North Europe (Ireland 🇮🇪) | Europe |
| North Europe (Ireland 🇮🇪) | West Europe (Netherlands 🇳🇱) | Europe |
| France Central (Paris 🇫🇷) | France South (Marseille 🇫🇷) — restricted access | France |
| Germany West Central (Frankfurt 🇩🇪) | Germany North (Berlin 🇩🇪) — restricted access | Germany |
| Norway East | Norway West — restricted access | Norway |
| Sweden Central | Sweden South — restricted access | Sweden |
| Switzerland North | Switzerland West — restricted access | Switzerland |
| UK South (London 🇬🇧) | UK West (Cardiff 🇬🇧) | United Kingdom |

**These European regions have no pair at all**: Austria East, Belgium Central, Denmark East, Italy North, Poland Central, Spain Central. Newer Azure regions generally ship without a pair and use **availability zones** as their redundancy story instead.

### ⚠️ Four things "paired regions" does *not* mean

Read these before you repeat the phrase "paired regions make us GDPR compliant" in a design doc.

1. **It is not a residency guarantee.** Microsoft's own wording is *"To meet data residency requirements, **almost all** regions reside within the same geography as their pair."* Almost. The documented counter-example is **Brazil South, which is paired with South Central US** — outside the Brazil geography, and an asymmetric pair at that (South Central US is *not* paired back to Brazil South). If you need a residency guarantee you get it from your own region choices, contractual commitments, and controls like Azure Policy — not from the pairing table.
2. **It is not global.** Only *"a small number of Azure services use these region pairs"* — geo-redundant storage (GRS) is the canonical one. Most services either replicate between arbitrary regions you choose, or do not replicate cross-region at all. "We're on a paired region" tells you nothing about where a *specific* service's second copy lands; you have to check that service.
3. **It is not automatic DR.** Microsoft states plainly: *"Deploying resources to a region in a pair doesn't automatically make them more resilient, nor does it provide automatic high availability, disaster recovery capabilities, or failover."* Microsoft-managed failover of GRS is reserved for catastrophic situations.
4. **It is not the EU residency product.** The thing Microsoft actually sells as an EU-residency commitment is the **EU Data Boundary**, a separate, contractual programme — plus per-service data-residency documentation. Region pairing is a reliability feature that *happens to be* geography-aware most of the time.

What paired regions genuinely give you, per Microsoft: a prioritised **region recovery sequence** during a geography-wide outage, **sequential updating** so a bad platform update does not hit both halves of a pair at once, and same-geography placement for the services that use pairs.

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
| 3 | Right to Erasure | Article 17 across replicas and backups; pseudonymisation vs anonymisation |
| 4 | Data Sovereignty Audit | Auditing where data lives, generating compliance reports |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 08-enterprise/gdpr-paired-regions

# Start both region databases + Adminer
docker compose up -d

# Install dependencies
uv sync

# Notebooks use the local .venv directly -- no global kernel to register.
# In VS Code: open the kernel picker (top-right) and select `.venv`.
# In classic Jupyter: uv run jupyter notebook notebooks/

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
│  │  (Python)    │───►│ :55433        │  │ :55434        │  │
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

Rather than guess at named companies' internal architectures, here are the *patterns* and where they come from — with the Azure facts checked against Microsoft's docs.

| Pattern | Driver | What the architecture does |
|---------|--------|----------------------------|
| **In-geography DR pair** | Customer contracts or a regulator that will not accept a non-EU secondary | Primary + secondary both inside the EU/EEA, e.g. West Europe ↔ North Europe. Verified per service, not assumed from the pairing table. |
| **In-country DR pair** | National/sector rules (e.g. German public-sector and some health/social-data rules) that want the secondary in the same country | Germany West Central ↔ Germany North, France Central ↔ France South. Note the secondary in each of these is a **restricted-access** region. |
| **Single-region + zones** | A newer EU region with no pair at all (Poland Central, Italy North, Spain Central, …) | Availability zones for intra-region redundancy; any cross-region copy is one you design and place yourself. |
| **Contractual EU boundary** | Enterprise/public-sector procurement | Microsoft's **EU Data Boundary** commitments layered on top of region choice — a contract, not a replication topology. |

> 🙅 We deliberately do **not** claim "Company X uses region pair Y". Public architecture claims about named companies age badly and are usually wrong in the details. (For the record: an earlier version of this README claimed Spotify uses a "Stockholm + Ireland" Azure pairing. Sweden Central's documented pair is **Sweden South**, not Ireland — and Spotify has publicly run on Google Cloud since 2016. Both halves of that claim were wrong.)

## 🚧 What This Lab Is Not

This is a teaching lab. Please read this section before borrowing anything from it.

- **Nothing here makes a system "GDPR compliant."** Compliance is an organisational and legal state — lawful basis, records of processing, DPIAs, contracts with processors, transfer assessments, security measures, governance. Code can *support* compliance; it cannot confer it. Where the notebooks print a score or a ✅, read it as *"this technical control is present and behaving"*, never as *"we are compliant"*.
- **This is not legal advice.** Article citations are here so you can go read the actual text at [gdpr-info.eu](https://gdpr-info.eu/). Retention periods, national derogations, and what counts as a valid lawful basis all vary by member state and by sector. Ask a real DPO.
- **The two Postgres containers are not Azure.** They are two independent databases on one laptop. Replication is done by hand in Python so you can watch it and break it. Real Azure geo-replication is inside the storage engine, has different failure modes, and does not lose a row because a Python cell raised an exception.
- **The threat model is missing.** Everything here runs unencrypted, with one shared superuser, no TLS, no key management, no access control, no tenant isolation, and no logging of *reads*. Integrity/confidentiality (Article 5(1)(f)) is a whole separate lab.
- **Backups are simulated.** Notebook 3 models a backup as a table copy so the erasure gap is visible in a few seconds. Real backup erasure involves retention windows, immutability/WORM policies, restore-time suppression lists, and offline media.

## Further Reading

- [GDPR Full Text](https://gdpr-info.eu/)
- [Azure region pairs and nonpaired regions](https://learn.microsoft.com/en-us/azure/reliability/regions-paired) — the authoritative pair list and the asymmetric-pair exceptions
- [Microsoft EU Data Boundary](https://learn.microsoft.com/en-us/privacy/eudb/eu-data-boundary-learn) — the actual EU residency commitment
- [Article 29 WP Opinion 05/2014 on Anonymisation Techniques](https://ec.europa.eu/justice/article-29/documentation/opinion-recommendation/files/2014/wp216_en.pdf) — why most "anonymised" data is really pseudonymised
- [Microsoft GDPR Compliance](https://learn.microsoft.com/en-us/compliance/regulatory/gdpr)
- [Azure Data Residency](https://azure.microsoft.com/en-us/explore/global-infrastructure/data-residency/)

## License

Educational content — feel free to use and modify for learning purposes.
