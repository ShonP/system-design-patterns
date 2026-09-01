# Privacy Review

📖 **Inspired by**: Privacy review processes at Microsoft, Google, Apple, and other large tech companies

## Overview

Every time an engineer at Microsoft builds a new feature, they cannot ship it until it passes a **Privacy Review**. This isn't optional — it's a mandatory gate in the release process, just like code review or security review.

**Why?** Because personal data is everywhere. A simple "add phone number to user profile" feature touches name, email, phone, address — all of which are legally protected by regulations like **GDPR** (Europe), **CCPA** (California), **HIPAA** (healthcare), and dozens of others.

One accidental data leak can cost a company hundreds of millions of dollars in fines, lawsuits, and lost trust. Microsoft was fined €20 million by the EU in 2023 for GDPR violations related to children's data in Xbox. Facebook paid $5 billion to the FTC. These aren't theoretical risks.

**This lab teaches you how privacy review works from the engineering side** — the actual processes, tools, and code you'd write to handle personal data responsibly.

## What is a Privacy Review?

A privacy review is a structured process where engineers and privacy experts examine a new feature or system to answer:

1. **What personal data does this feature collect?** (names, emails, locations, behavior)
2. **Why do we need it?** (what's the business purpose)
3. **Who can access it?** (which teams, third parties, countries)
4. **How long do we keep it?** (retention policies)
5. **How do we protect it?** (encryption, access controls, anonymization)
6. **Can users control their data?** (delete, export, opt-out)

Think of it like a building inspection — you wouldn't let people move into an apartment without checking the wiring, plumbing, and fire safety. Privacy review checks that personal data is "wired" correctly.

## Data Classification

Not all data is equally sensitive. Companies use a **classification system** to label every piece of data:

| Level | Description | Examples | Who Can Access |
|-------|-------------|----------|----------------|
| 🟢 **Public** | Safe to share with anyone | Product names, public docs, blog posts | Everyone |
| 🔵 **Internal** | OK within the company | Employee count, office locations, internal wikis | All employees |
| 🟡 **Confidential** | Personal or business-sensitive | Customer names, emails, phone numbers, revenue | Authorized teams only |
| 🔴 **Restricted** | Highest sensitivity | SSNs, credit cards, health records, passwords, exact dates of birth | Named individuals with audit trail |

**The rule**: every database column, every API field, every log entry must be classified. If you don't know what level a piece of data is, treat it as **Restricted** until classified.

Date of birth sits in Restricted for a reason that is easy to miss: on its own it
looks like a birthday, but combined with a ZIP code and sex it re-identifies most
of the US population (Sweeney, 2000). Notebook 1's scanner and the registry in
`db/init.sql` agree on this — when a taxonomy disagrees with itself, the registry
becomes a coin flip.

### Why Classification Matters

Imagine you're building a dashboard that shows customer orders. The order total is **Internal** (fine to display to support agents), but the shipping address is **Confidential** (only show to shipping team). Without classification, you might accidentally expose addresses to everyone with dashboard access.

## Privacy Impact Assessments (PIAs)

A **Privacy Impact Assessment** is a document that answers "what could go wrong with personal data in this feature?" before the feature ships.

### When is a PIA Required?

At Microsoft, a PIA is required when:
- Collecting **new types** of personal data
- Sharing data with a **new third party**
- Transferring data **across country borders**
- Using data for **automated decision-making** (e.g., AI scoring)
- Processing **children's data** (under 13 in US, under 16 in EU)
- Any feature touching **Restricted** data

### What's in a PIA?

1. **Data Flow Diagram** — where does data come from, where does it go?
2. **Purpose Specification** — why is each data element needed?
3. **Risk Assessment** — what happens if this data leaks? (scored 1-5)
4. **Mitigation Plan** — how do we reduce each risk?
5. **Approval** — sign-off from privacy team, legal, and engineering lead

### Risk Scoring

| Score | Level | Meaning | Example |
|-------|-------|---------|---------|
| 1 | Negligible | No personal data involved | Caching product catalog |
| 2 | Low | Pseudonymized or aggregated data | Analytics with user IDs hashed |
| 3 | Medium | Confidential PII with access controls | Customer support portal |
| 4 | High | Restricted data or cross-border transfer | Payment processing |
| 5 | Critical | Sensitive categories + automated decisions | AI-based credit scoring |

## Data Retention Policies

**Data retention** answers: "How long do we keep this data, and what happens when that time is up?"

The principle is simple: **don't keep data longer than you need it**. Every day you store personal data is another day it could be breached.

### Common Retention Periods

| Data Type | Typical Retention | Why |
|-----------|------------------|-----|
| Activity logs | 90 days | Enough for debugging, not worth the risk longer |
| Support tickets | 1 year | May need for follow-up or disputes |
| Order history | 7 years | Tax law requires financial records |
| Deleted accounts | 30 days grace | Allow account recovery, then hard delete — counted from the **deletion request**, not from account creation |
| Payment cards | Delete on removal | No reason to keep after customer removes |

### Purge Strategies

- **Hard Delete**: Remove the rows entirely. Used when no legal hold applies.
- **Soft Delete**: Mark as deleted but keep in database. Used during grace periods.
- **Anonymize**: Replace PII with fake/hashed values but keep the record for analytics.

Each policy also has to name the **clock** it runs on. "One year after
resolution" is `resolved_at`; "30-day grace period" is the deletion request
timestamp. Running everything off `created_at` is a different policy that happens
to compile — and it deletes accounts that were still inside the recovery window
you promised them.

## Anonymization vs Pseudonymization

These two terms sound similar but are **legally different**:

### Pseudonymization
Replace direct identifiers with tokens, but **keep a mapping table** that can reverse it.

```
Alice Smith → User_A7X2K (mapping stored separately)
```

- Still counts as personal data under GDPR (because it's reversible)
- Useful for internal analytics where you might need to re-identify
- Reduces risk if the main database is breached (attacker only gets tokens)

### Anonymization
Transform data so it **cannot be reversed** — no mapping, no way back.

```
Alice Smith, age 34, Seattle → [removed], age 30-40, Pacific Northwest
```

- Not personal data under GDPR (irreversible)
- Useful for public research datasets, aggregated reporting
- Must resist re-identification attacks (k-anonymity, l-diversity)

### Techniques Covered in This Lab

| Technique | Type | How It Works |
|-----------|------|--------------|
| **k-Anonymity** | Anonymization | Every record looks like at least k-1 others **on the quasi-identifiers you declared** — reached by generalizing, and by suppressing the records that generalizing cannot hide |
| **l-Diversity** | Anonymization | Each group has at least l different sensitive values (the distinct form still leaks when one value dominates) |
| **Differential Privacy** | Anonymization | Add calibrated noise so individual records can't be identified — meaningful only with a **privacy budget** tracked across every query |
| **Tokenization** | Pseudonymization | Replace values with random tokens, store mapping separately. Still personal data: the tokens link records together |

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Data Classification | Scan databases for PII, classify columns, tag sensitive data |
| 2 | Privacy Impact Assessment | Build a PIA workflow, score risks, document data flows |
| 3 | Anonymization Techniques | k-anonymity, l-diversity, differential privacy, tokenization |
| 4 | Data Retention & Purging | Implement retention policies, automated purging, audit trails |

## What This Lab Demonstrates — and What It Doesn't

Everything here runs against one PostgreSQL database with 50 synthetic users, and
the code is deliberately readable rather than complete. Four things to keep in
mind before borrowing any of it:

- **The PII scanner misses a lot.** Notebook 1 measures its own recall against a
  human-labelled ground truth and finds roughly a third of the PII. Regex cannot
  see a person's name or a free-form address. "The scan found nothing" is not
  evidence that a column is clean, and any process that treats it that way is
  worse than no scanner at all.
- **Anonymization here is a demonstration, not a release process.** A real data
  release needs a threat model, a review of what auxiliary datasets it could be
  joined against, and someone who tries to break it before it ships.
- **Erasure reaches further than one database.** Backups, replicas, WAL, search
  indexes, caches, warehouses, trained models, object storage and third-party
  processors all hold copies. Notebook 4 lists them; it only implements the
  database.
- **Legal hold is not implemented.** An active litigation hold overrides
  retention, and a purge engine that does not check for one is a liability.

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 08-enterprise/privacy-review

# Start PostgreSQL + Redis + Visualization Tools
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
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `privacy_review`
- **Use for**: Explore PII in tables, see classification tags, watch data get anonymized

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: View tokenization mappings, PIA cache, retention policy cache

## Why Microsoft Requires This for Every Feature

Microsoft ships software used by billions of people. A single privacy mistake in Windows, Office, Azure, or Xbox can:

1. **Trigger regulatory fines** — GDPR fines can reach 4% of global revenue (~$8 billion for Microsoft)
2. **Destroy customer trust** — enterprise customers (governments, banks, hospitals) won't use products that mishandle data
3. **Create legal liability** — class-action lawsuits from affected users
4. **Damage reputation** — news headlines about data breaches persist for years

So Microsoft built privacy review into the engineering process itself:

- **SDL (Security Development Lifecycle)** includes privacy requirements at every stage
- **Privacy dashboards** track classification coverage across all services
- **Automated scanners** flag unclassified PII in code reviews
- **Retention enforcement** automatically purges data past its retention date
- **Data subject requests** (delete my data) must complete within 30 days

This isn't unique to Microsoft — Google, Apple, Meta, Amazon, and every major tech company has similar processes. If you want to work at any of these companies, understanding privacy engineering is essential.

## License

Educational content — feel free to use and modify for learning purposes.
