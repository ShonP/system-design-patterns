# Payment System

📖 **Source**: [Hello Interview – Payment System](https://www.hellointerview.com/learn/system-design/problem-breakdowns/payment-system)

## Overview

A payment system like Stripe lets businesses (merchants) accept money from customers without building their own payment infrastructure. The customer enters card details on a merchant's website, the merchant sends the request to our platform, and we handle authorization, capture, and settlement with the card networks.

Building a payment system is one of the most challenging system design problems because **money cannot be lost, duplicated, or misattributed**. Every transaction must be durable, auditable, and exactly-once. This lab walks you through the core building blocks hands-on.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Payment Processing Pipeline | Requirements + capacity estimate, the full lifecycle (intent → transaction → settlement), timeout reconciliation |
| 2 | Idempotency & Exactly-Once Payments | Idempotency keys **proven under 8-way concurrency**, plus the same-key-different-payload trap and a request fingerprint to catch it |
| 3 | Ledger & Double-Entry Bookkeeping | Debits == credits (**asserted**), a deferred constraint trigger that makes an unbalanced commit impossible, refunds, and **settlement reconciliation** |
| 4 | Fraud Detection Basics | Simple rule-based signals to flag suspicious transactions |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL

## Quick Start

```bash
# Navigate to the lab directory
cd 06-system-designs/payment-system

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
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `payment_demo`
- **Use for**: Inspect payment intents, transactions, ledger entries, and audit logs

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch idempotency keys, payment status caches, and fraud rule counters

## Key Concepts Covered

### Core Entities
- **Merchant** — the business using our payment platform
- **PaymentIntent** — the merchant's intention to collect money (tracks the full lifecycle)
- **Transaction** — an individual money-movement record (charge, refund, etc.)

### Payment Lifecycle (State Machine)
```
created → processing → succeeded
                    → failed
```

### Idempotency
- Retry-safe payments using `(merchant_id, idempotency_key)` unique constraint
- If a network timeout occurs, the merchant retries with the same key and gets the original result

### Double-Entry Bookkeeping
- Every charge creates **two** ledger rows: a debit and a credit
- Total debits must **always** equal total credits (the fundamental accounting equation)
- A `DEFERRABLE INITIALLY DEFERRED` constraint trigger rejects an unbalanced transaction at `COMMIT`, so the invariant is enforced rather than merely checked
- **Balanced books can still be wrong.** Notebook 3 reconciles the ledger against a processor settlement file and surfaces the three break types: missing in ledger, missing in settlement, amount mismatch

### Fraud Detection
- Velocity checks (too many charges in a short window)
- Amount anomalies (unusually large charges)
- Card testing patterns (many small charges in rapid succession)

## Real-World Examples

| System | Why Payment Design Matters |
|--------|---------------------------|
| Stripe | Processes billions in payments; idempotency and ledger integrity are core |
| Square | POS payments need sub-second auth with offline fallback |
| PayPal | Multi-currency settlement across global banking networks |
| Shopify | Merchant platform where a single bug could double-charge millions of orders |

## License

Educational content — feel free to use and modify for learning purposes.
