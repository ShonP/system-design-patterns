# Long-Running Jobs with Temporal

📖 **What you'll learn**: How large enterprises (Microsoft, Netflix, Uber) orchestrate long-running jobs that must survive crashes, handle failures gracefully, and scale to millions of executions.

## The Problem

Imagine you're building an e-commerce system. When a customer places an order, you need to:

1. **Create the order** in your database
2. **Charge their credit card** via Stripe
3. **Reserve inventory** in the warehouse
4. **Schedule shipping** with FedEx
5. **Send a confirmation email**

Each step calls a different service. Each can fail. Each takes different amounts of time. What happens when step 3 fails after step 2 already charged the customer's card?

**This is the distributed transactions problem**, and it's one of the hardest challenges in system design.

### Why Cron + Database Polling Doesn't Work

Many teams start with a "job table" approach:

```
┌──────────────────────────────────────────────────┐
│  jobs table                                       │
│  id | type    | status  | payload | retry_count  │
│  1  | order   | pending | {...}   | 0            │
│  2  | order   | failed  | {...}   | 3            │
└──────────────────────────────────────────────────┘

Cron job runs every 60 seconds:
  SELECT * FROM jobs WHERE status = 'pending' LIMIT 100;
  → Process each job
  → UPDATE jobs SET status = 'completed' WHERE id = ?;
```

This breaks in many ways:
- **No retries with backoff** — you have to build retry logic yourself
- **No visibility** — which step failed? What was the error?
- **No compensation** — if step 3 fails, how do you undo steps 1 and 2?
- **Lost jobs** — if the server crashes mid-processing, the job is stuck
- **No rate limiting** — a burst of jobs can overwhelm downstream services
- **Polling waste** — checking every 60 seconds burns CPU even when idle

## Enter Temporal: Durable Execution

**Temporal** is a workflow orchestration engine that solves all these problems. Your code looks like normal Python, but Temporal makes it **indestructible**:

```python
@workflow.defn
class OrderWorkflow:
    @workflow.run
    async def run(self, order_id: str):
        await workflow.execute_activity(create_order, order_id, ...)
        await workflow.execute_activity(charge_payment, order_id, ...)
        await workflow.execute_activity(reserve_inventory, order_id, ...)
        await workflow.execute_activity(ship_order, order_id, ...)
```

If your server crashes after `charge_payment` succeeds, Temporal **automatically resumes** from exactly where it left off — it won't re-charge the customer.

### Who Uses Temporal?

| Company | Use Case |
|---------|----------|
| **Microsoft** | Azure Durable Functions (built on similar concepts) |
| **Netflix** | Media encoding pipelines, content delivery |
| **Uber** | Trip lifecycle, payment processing |
| **Snap** | Ad delivery, content moderation |
| **Stripe** | Payment orchestration |
| **Coinbase** | Cryptocurrency transaction processing |
| **Datadog** | Infrastructure provisioning |

## Key Concepts Covered

### 🔄 Saga Pattern
When a multi-step process fails halfway through, you need to **undo** the completed steps. The Saga pattern maintains a list of "compensation" actions that run in reverse order on failure.

### 🛡️ Idempotency
Activities should be safe to retry. If Temporal retries `charge_payment`, it shouldn't charge the customer twice. You achieve this with idempotency keys.

### 🔁 Retry Policies
Temporal automatically retries failed activities with configurable:
- **Initial interval** — how long to wait before first retry
- **Backoff coefficient** — multiply wait time by this after each retry
- **Maximum attempts** — give up after N tries
- **Non-retryable errors** — some errors (like "invalid credit card") shouldn't be retried

### 🧒 Child Workflows
Break complex processes into smaller, independently manageable workflows. A "parent" workflow can spawn "child" workflows that run concurrently.

### 📡 Signals
Send data to a running workflow from the outside. Perfect for human-in-the-loop approvals: "pause the order until a manager approves."

### ⏰ Timers
Workflows can sleep for minutes, hours, or even months. Temporal handles this efficiently without consuming resources while waiting.

### 📌 Versioning
Safely update workflow logic while existing workflows are still running. Critical for production systems that can't afford downtime.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Why Temporal? | Problems with cron+DB polling, intro to workflow engines |
| 2 | Basic Workflows | Defining workflows and activities, running a simple pipeline |
| 3 | Saga Pattern | Multi-step transactions with compensation and rollback |
| 4 | Advanced Patterns | Child workflows, signals, timers, versioning |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of async Python (`async`/`await`)

## Quick Start

```bash
# Navigate to the lab directory
cd enterprise-patterns/long-running-jobs-temporal

# Start Temporal + PostgreSQL + UI
docker compose up -d

# Wait ~30 seconds for Temporal to initialize, then verify it's running
docker compose ps

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=temporal --display-name="Temporal (Python)"

# Open the first notebook and start learning!
```

## 🔍 Temporal Web UI

- **URL**: http://localhost:8080
- **Use for**: Inspect running workflows, view event history, send signals, terminate stuck workflows
- No login required for local development

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Your Code                                  │
│                                                                    │
│  ┌─────────────┐     ┌──────────────┐     ┌───────────────────┐  │
│  │   Client     │────▶│  Temporal     │────▶│   Worker          │  │
│  │  (notebook)  │     │  Server       │     │  (runs your code) │  │
│  │              │     │  port 7233    │     │                   │  │
│  │ "Start this  │     │ "I'll track   │     │ "I'll execute     │  │
│  │  workflow"   │     │  the state"   │     │  the activities"  │  │
│  └─────────────┘     └──────┬───────┘     └───────────────────┘  │
│                              │                                     │
│                     ┌────────▼────────┐                           │
│                     │   PostgreSQL     │                           │
│                     │  (event store)   │                           │
│                     └─────────────────┘                           │
└──────────────────────────────────────────────────────────────────┘
```

**Client** → tells Temporal "please run this workflow with these parameters"
**Temporal Server** → records every step as events in PostgreSQL, schedules tasks
**Worker** → polls Temporal for tasks, executes your activity/workflow code
**PostgreSQL** → stores the complete history of every workflow execution

## Stopping the Lab

```bash
docker compose down          # Stop containers
docker compose down -v       # Stop containers AND delete data
```

## License

Educational content — feel free to use and modify for learning purposes.
