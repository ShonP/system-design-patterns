# Business Continuity & Disaster Recovery (BCDR)

📖 **Pattern**: Enterprise-grade resilience — keeping systems running when things go wrong.

## Overview

Business Continuity and Disaster Recovery (BCDR) is the set of practices that keep critical systems running during failures — from a single server crash to an entire data center going offline.

**Why does this matter?** Consider these real-world costs of downtime:

| Company/Industry | Cost of 1 Hour Downtime |
|-----------------|------------------------|
| Amazon | ~$34 million |
| Banking/Finance | ~$9.3 million |
| Healthcare | ~$636,000 + patient safety risks |
| E-commerce | ~$300,000 |

Every major enterprise (Microsoft Azure, AWS, banks, hospitals) invests heavily in BCDR. If you work at any serious company, you **will** encounter these patterns.

## Key Concepts

### RPO vs RTO — The Two Numbers That Drive Everything

| Metric | Stands For | What It Means | Example |
|--------|-----------|---------------|---------|
| **RPO** | Recovery Point Objective | How much data can you afford to **lose**? | "We can lose at most 5 minutes of transactions" |
| **RTO** | Recovery Time Objective | How long can you be **down**? | "We must be back online within 15 minutes" |

Think of it this way:
- **RPO** looks **backward** — how far back in time do you go when you recover?
- **RTO** looks **forward** — how long until you're back up and running?

```
    Data Loss (RPO)          Downtime (RTO)
    ◄──────────────►         ◄──────────────►
                    │                        │
───────────────────[DISASTER]────────────────[RECOVERED]──────
    last backup     failure                  back online
```

### Hot / Warm / Cold Standby

| Type | Description | RTO | Cost |
|------|-------------|-----|------|
| **Hot Standby** | Server running + data synced in real-time. Ready to take over instantly. | Seconds to minutes | $$$ |
| **Warm Standby** | Server running + periodic data sync. Needs brief catch-up. | Minutes to hours | $$ |
| **Cold Standby** | Server exists but is OFF. Must boot + restore data from backup. | Hours to days | $ |

**This lab uses Hot Standby** — PostgreSQL streaming replication keeps the standby database synchronized in real-time.

### Failover Strategies

1. **Automatic Failover** — A monitoring system detects failure and promotes the standby automatically (e.g., Patroni, pg_auto_failover).
2. **Manual Failover** — A human decides to promote the standby. Slower but avoids false positives.
3. **DNS-based Failover** — Update DNS records to point to the new primary. Simple but has TTL delays.
4. **Load Balancer Failover** — The load balancer routes traffic to healthy servers automatically.

### Split-Brain Problem

The most dangerous scenario in failover: **both servers think they are the primary** and accept writes independently. This causes data divergence that is extremely hard to fix.

Prevention strategies:
- **Fencing** — physically shut down the old primary before promoting the standby
- **Quorum** — require majority agreement before promotion (odd number of nodes)
- **Watchdog timers** — automatic shutdown if a node loses contact with the cluster

### Backup Testing — The Most Neglected Practice

> "An untested backup is not a backup — it's a hope."

Enterprises must regularly:
1. **Restore backups** to a test environment
2. **Verify data integrity** — row counts, checksums, application-level checks
3. **Measure actual recovery time** — does it meet your RTO?
4. **Document the procedure** — can someone else do it at 3 AM?

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | RPO & RTO Fundamentals | Recovery objectives, business impact analysis, SLA math |
| 2 | Database Replication & Failover | Streaming replication, promoting a standby, split-brain prevention |
| 3 | Backup Strategies | Full/incremental/differential backups, point-in-time recovery, verification |
| 4 | Disaster Recovery Drill | Simulating failure, executing failover, measuring actual RTO |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and databases

## Quick Start

```bash
# Navigate to the lab directory
cd enterprise-patterns/bcdr

# Start all services (PostgreSQL primary + standby, Redis primary + replica, etc.)
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=bcdr --display-name="BCDR (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `pg-primary`, Username `demo`, Password `demo`, Database `bcdr_demo`
- **Use for**: Compare data between primary and standby, watch replication

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Add two databases:
  - Primary: Host `redis-primary`, Port `6379`
  - Replica: Host `redis-replica`, Port `6379`
- **Use for**: Watch keys replicate from primary to replica

### Health Dashboard (Nginx)
- **URL**: http://localhost:8090
- **Use for**: Quick overview of service health endpoints

## Architecture Diagram

```
                    ┌─────────────────────────────┐
                    │      Health Dashboard        │
                    │      (nginx :8090)           │
                    └─────────────────────────────┘

    ┌──────────────────┐         ┌──────────────────┐
    │  PostgreSQL       │ ──WAL──▶│  PostgreSQL       │
    │  PRIMARY (:5432)  │ Stream  │  STANDBY (:5433)  │
    │  (reads + writes) │         │  (read-only)      │
    └──────────────────┘         └──────────────────┘

    ┌──────────────────┐         ┌──────────────────┐
    │  Redis            │ ──Sync──▶│  Redis            │
    │  PRIMARY (:6379)  │         │  REPLICA (:6380)  │
    │  (reads + writes) │         │  (read-only)      │
    └──────────────────┘         └──────────────────┘

    ┌──────────────────┐         ┌──────────────────┐
    │  Adminer (:8080)  │         │  RedisInsight     │
    │  PostgreSQL GUI   │         │  (:5540) Redis GUI│
    └──────────────────┘         └──────────────────┘
```

## Real-World BCDR Examples

| Organization | BCDR Strategy |
|-------------|---------------|
| **Microsoft Azure** | Paired regions, availability zones, geo-redundant storage |
| **JPMorgan Chase** | Active-active data centers, <15 min RTO for critical systems |
| **Epic (Healthcare)** | Real-time replication, RPO near-zero for patient records |
| **Netflix** | Chaos Engineering (Chaos Monkey), multi-region active-active |
| **NYSE** | Hot standby in separate building, <30 second failover |

## License

Educational content — feel free to use and modify for learning purposes.
