# Job Scheduler

📖 **Source**: [Hello Interview – Job Scheduler](https://www.hellointerview.com/learn/system-design/problem-breakdowns/job-scheduler)

## Overview

A job scheduler is a system that automatically schedules and executes jobs at specified times or intervals. Think of it like an alarm clock for your code — you tell it *what* to run, *when* to run it, and it handles the rest.

Two key terms before we start:

- **Task** — the abstract concept of work to be done (e.g. "send an email"). Tasks are reusable templates.
- **Job** — an instance of a task with a specific schedule and parameters (e.g. "send an email to bob@example.com every Monday at 9 AM").

Real-world examples: cron jobs, Airflow DAGs, Celery beat, AWS EventBridge Scheduler, and every "scheduled report" feature you've ever used.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Job Queue Design & Priority Scheduling | Priority queues with Redis sorted sets, fair scheduling, starvation prevention |
| 2 | Distributed Task Execution | Worker pools, visibility timeouts, at-least-once delivery, idempotency |
| 3 | Cron-Like Scheduling & Dead Letter Queues | Recurring schedules with croniter, two-phase architecture, DLQ handling |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of SQL and Redis

## Quick Start

```bash
# Navigate to the lab directory
cd system-designs/job-scheduler

# Start PostgreSQL + Redis + Visualization Tools
docker-compose up -d

# Create virtual environment and install dependencies
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Register Jupyter kernel
python -m ipykernel install --user --name=job-scheduler --display-name="Job Scheduler (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `job_scheduler`
- **Use for**: Inspect jobs, executions, and dead letter queue tables

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Watch priority queues, see delayed jobs, monitor worker heartbeats

## Key Concepts Covered

### Core Architecture
- **Two-phase scheduling** — DB poll for durability + message queue for precision
- **Job vs Execution separation** — one recurring job creates many execution rows
- **Priority queues** — Redis sorted sets (ZSET) with timestamp scores

### Execution Guarantees
- **At-least-once delivery** — visibility timeouts ensure no job is lost
- **Idempotency** — designing tasks that are safe to retry
- **Exponential backoff** — gradually increasing retry delays

### Failure Handling
- **Dead letter queues** — permanently failed jobs go here for investigation
- **Worker heartbeats** — detecting crashed workers
- **Poison pill detection** — identifying jobs that always fail

### Scheduling
- **Cron expressions** — `0 9 * * 1` means "every Monday at 9 AM"
- **Immediate & one-time jobs** — fire-and-forget or schedule for a future date
- **Next-run calculation** — using croniter to compute upcoming executions

## System Design Interview Tips

| Requirement | Key Design Decision |
|-------------|-------------------|
| Execute 10k jobs/sec | Horizontal worker scaling + queue-based distribution |
| Within 2s of scheduled time | Two-phase: DB poll every 5 min → priority queue for precision |
| At-least-once execution | Visibility timeouts + retry with exponential backoff |
| High availability | Stateless workers + durable queue + persistent DB |

## License

Educational content — feel free to use and modify for learning purposes.
