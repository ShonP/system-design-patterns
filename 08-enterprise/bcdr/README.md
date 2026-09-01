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

### Run them in order — and mind the state notebook 2 leaves behind

Notebook 2 ends **mid-disaster on purpose**: it fences the primary (stops the
container — the STONITH step of a real failover) and promotes the standby.
That is the state an on-call engineer is actually handed, and it is not a
state notebooks 3 and 4 can run in: port 5432 is dead, and the promoted node
on 55433 now holds a write the fenced node has never seen.

Notebooks 3 and 4 therefore open with a **failback** cell. It captures the
writes made on the promoted node during the outage, un-fences the old primary,
replays those writes onto it, re-clones the standby, and verifies the result.
Running it when nothing is wrong is a no-op, so you can start from notebook 3
on a cold stack without thinking about it.

Notebook 4 also *ends* with a failback (Phase 6), so a completed drill leaves
the cluster back in a shape that could survive the next failure — and the
whole series is re-runnable without `docker compose down -v`.

## ⚖️ What this lab does NOT do

Being honest about the gap between a laptop and a real BCDR programme:

| Concern | This lab | Production |
|---------|----------|------------|
| Failover trigger | A human runs a notebook cell | Patroni / pg_auto_failover with leader leases and consensus |
| Quorum | None — two nodes, split-brain prevented by fencing by hand | 3 or 5 nodes, majority required to promote |
| Failback | Row-level carry-back of the one table this lab writes during a failover | `pg_rewind` + WAL replay, which handles every table and preserves row identity |
| Off-site copy | Nothing leaves the laptop | Second region / account / provider, plus an immutable copy |
| Replication mode | Asynchronous only, so RPO is structurally > 0 | Synchronous where RPO 0 is a real requirement — paid for on every write |
| Scale | 500 orders, sub-second replication lag | Terabytes, WAL shipping over a WAN, lag measured in seconds |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and databases

## Quick Start

```bash
# Navigate to the lab directory
cd 08-enterprise/bcdr

# Start all services (PostgreSQL primary + standby, Redis primary + replica, etc.)
docker compose up -d

# Install dependencies (creates .venv automatically)
uv sync

# Open any notebook in VS Code and pick the `.venv` kernel from the
# kernel picker (top-right). If it does not appear, reload the window:
# Cmd+Shift+P → "Reload Window".
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
    │  PRIMARY (:5432)  │ Stream  │  STANDBY (:55433)  │
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

## 📰 Famous Outages That Shaped BCDR Practice

These incidents each cost their companies millions and changed how the
industry thinks about resilience. They map directly to the concepts in this lab.

| Year | Incident | What happened | BCDR lesson |
|------|----------|--------------|--------------|
| 2017 | **GitLab db1 deletion** | An engineer ran `rm -rf` on the wrong primary; 5 of 6 backup mechanisms were broken | Untested backups = hope. Restore was ~18h, and some data was lost forever. → Notebooks 3 & 4 |
| 2017 | **Maersk NotPetya** | Ransomware encrypted ~50,000 machines globally; recovered only because a single DC in Ghana was offline during the attack | Off-site + air-gapped copies (3-2-1-1 rule). → Notebook 3 |
| 2017 | **British Airways IT outage** | Power supply failure at a London DC caused a 3-day disruption; ~$100M loss | Redundant power, tested failover, multi-region. → Notebook 4 |
| 2016 | **Delta Air Lines** | A single power-control module failed, 2,000 flights cancelled, ~$150M loss | Don't assume "the DC has backup power" — test it. → Notebook 4 |
| 2021 | **Facebook 6-hour outage** | A BGP config push cut FB off the internet; even internal tools used FB auth | BCDR includes your *recovery tools* too. → Notebook 4 |
| 2019 | **Salesforce permission bug** | A script gave all users admin rights; forced global read-only for ~15 hours | Logical errors replicate instantly. Backups + PITR are the only recovery. → Notebook 3 |
| 2022 | **Rogers (Canada) outage** | Routing change knocked out the entire network for ~19h — including 911 | Change-management + staged rollouts are part of BCDR. |

**Pattern across all of these**: the technology to prevent the outage
already existed. What failed was **testing the recovery plan under realistic
conditions** — exactly what Notebook 4 (Disaster Recovery Drill) teaches.

## License

Educational content — feel free to use and modify for learning purposes.
