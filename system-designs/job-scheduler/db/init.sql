-- Job Scheduler Lab Database
-- Models the core entities: tasks, jobs, executions, and dead letter queue

-- ============================================================
-- Tasks: reusable definitions of work to be done
-- Think of a task as a template — e.g. "send an email"
-- ============================================================
CREATE TABLE tasks (
    id VARCHAR(100) PRIMARY KEY,           -- human-readable id like "send_email"
    name VARCHAR(255) NOT NULL,
    description TEXT,
    handler VARCHAR(255) NOT NULL,         -- which function runs this task
    max_retries INTEGER DEFAULT 3,
    timeout_seconds INTEGER DEFAULT 300,   -- 5-minute default timeout
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Jobs: a scheduled instance of a task
-- A job = task + schedule + parameters
-- ============================================================
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(100) NOT NULL,
    task_id VARCHAR(100) NOT NULL REFERENCES tasks(id),
    schedule_type VARCHAR(10) NOT NULL CHECK (schedule_type IN ('IMMEDIATE', 'DATE', 'CRON')),
    schedule_value VARCHAR(100),            -- cron expression or ISO datetime
    parameters JSONB DEFAULT '{}',          -- task-specific input
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Executions: each individual run of a job
-- Separating jobs from executions is a key design insight —
-- one recurring job creates many execution rows.
-- ============================================================
CREATE TABLE executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'QUEUED', 'RUNNING', 'COMPLETED', 'FAILED', 'RETRYING')),
    scheduled_at TIMESTAMP NOT NULL,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    attempt INTEGER DEFAULT 0,
    worker_id VARCHAR(100),                 -- which worker picked this up
    result JSONB,                           -- output or error details
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Dead Letter Queue: permanently failed executions
-- After max retries, failed jobs land here for investigation.
-- ============================================================
CREATE TABLE dead_letter_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id UUID NOT NULL REFERENCES executions(id),
    job_id UUID NOT NULL REFERENCES jobs(id),
    task_id VARCHAR(100) NOT NULL REFERENCES tasks(id),
    parameters JSONB,
    error_message TEXT,
    attempts INTEGER,
    failed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes for common access patterns
-- ============================================================

-- "Find pending executions that should run soon" — the core scheduler query
CREATE INDEX idx_executions_pending ON executions(scheduled_at)
    WHERE status = 'PENDING';

-- "Show me all executions for a specific job"
CREATE INDEX idx_executions_job ON executions(job_id);

-- "Show me all jobs for a specific user"
CREATE INDEX idx_jobs_user ON jobs(user_id);

-- "Find active cron jobs to schedule next runs"
CREATE INDEX idx_jobs_cron ON jobs(task_id)
    WHERE schedule_type = 'CRON' AND is_active = TRUE;

-- ============================================================
-- Seed data: sample tasks
-- ============================================================
INSERT INTO tasks (id, name, description, handler, max_retries, timeout_seconds) VALUES
    ('send_email',      'Send Email',           'Sends an email to the specified recipient',    'handlers.send_email',      3, 30),
    ('generate_report', 'Generate Report',      'Generates a PDF report from data',             'handlers.generate_report', 2, 120),
    ('resize_image',    'Resize Image',         'Resizes an image to specified dimensions',     'handlers.resize_image',    3, 60),
    ('cleanup_temp',    'Cleanup Temp Files',   'Removes temporary files older than 24 hours',  'handlers.cleanup_temp',    1, 300),
    ('sync_inventory',  'Sync Inventory',       'Syncs product inventory with warehouse API',   'handlers.sync_inventory',  3, 180),
    ('send_webhook',    'Send Webhook',         'Sends an HTTP POST to a webhook URL',          'handlers.send_webhook',    5, 30),
    ('backup_database', 'Backup Database',      'Creates a database backup',                    'handlers.backup_database', 2, 600);

-- ============================================================
-- Seed data: sample jobs with different schedule types
-- ============================================================
INSERT INTO jobs (id, user_id, task_id, schedule_type, schedule_value, parameters) VALUES
    -- Immediate job
    ('a0000000-0000-0000-0000-000000000001', 'user_alice', 'send_email', 'IMMEDIATE', NULL,
     '{"to": "bob@example.com", "subject": "Welcome!", "body": "Hello Bob"}'),

    -- One-time scheduled job
    ('a0000000-0000-0000-0000-000000000002', 'user_alice', 'generate_report', 'DATE', '2026-04-15T09:00:00',
     '{"report_type": "monthly_sales", "format": "pdf"}'),

    -- Recurring cron jobs
    ('a0000000-0000-0000-0000-000000000003', 'user_bob', 'send_email', 'CRON', '0 9 * * 1',
     '{"to": "team@example.com", "subject": "Weekly standup reminder"}'),

    ('a0000000-0000-0000-0000-000000000004', 'user_bob', 'cleanup_temp', 'CRON', '0 2 * * *',
     '{"older_than_hours": 24}'),

    ('a0000000-0000-0000-0000-000000000005', 'user_charlie', 'sync_inventory', 'CRON', '*/15 * * * *',
     '{"warehouse": "east_coast"}'),

    ('a0000000-0000-0000-0000-000000000006', 'user_charlie', 'backup_database', 'CRON', '0 3 * * 0',
     '{"database": "production", "destination": "s3://backups/"}');

-- ============================================================
-- Seed data: sample executions in various states
-- ============================================================
INSERT INTO executions (job_id, status, scheduled_at, started_at, completed_at, attempt, worker_id, result) VALUES
    -- Completed executions
    ('a0000000-0000-0000-0000-000000000001', 'COMPLETED',
     NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours' + INTERVAL '2 seconds',
     1, 'worker-1', '{"message_id": "msg_abc123"}'),

    ('a0000000-0000-0000-0000-000000000003', 'COMPLETED',
     NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '5 seconds',
     1, 'worker-2', '{"emails_sent": 1}'),

    -- A failed execution
    ('a0000000-0000-0000-0000-000000000005', 'FAILED',
     NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '29 minutes',
     3, 'worker-1', '{"error": "Connection timeout to warehouse API"}'),

    -- Pending executions (waiting to be picked up)
    ('a0000000-0000-0000-0000-000000000004', 'PENDING',
     NOW() + INTERVAL '30 minutes', NULL, NULL, 0, NULL, NULL),

    ('a0000000-0000-0000-0000-000000000005', 'PENDING',
     NOW() + INTERVAL '15 minutes', NULL, NULL, 0, NULL, NULL),

    ('a0000000-0000-0000-0000-000000000006', 'PENDING',
     NOW() + INTERVAL '2 days', NULL, NULL, 0, NULL, NULL);
