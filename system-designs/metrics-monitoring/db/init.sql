-- Metrics Monitoring Lab Database
-- Stores alert rules, notification configs, and metric metadata

-- ============================================================
-- Alert rules table
-- Users define conditions like "avg CPU > 90% for 5 minutes"
-- ============================================================
CREATE TABLE alert_rules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    query TEXT NOT NULL,             -- PromQL-like expression
    threshold DECIMAL(10,4) NOT NULL,
    operator VARCHAR(10) NOT NULL DEFAULT '>',  -- >, <, >=, <=, ==
    duration_seconds INTEGER NOT NULL DEFAULT 300, -- how long condition must hold
    severity VARCHAR(20) NOT NULL DEFAULT 'warning', -- info, warning, critical
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Notification channels
-- Where alerts get sent (Slack, email, PagerDuty, etc.)
-- ============================================================
CREATE TABLE notification_channels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    channel_type VARCHAR(50) NOT NULL,  -- slack, email, pagerduty, webhook
    config JSONB NOT NULL,              -- channel-specific settings
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Link alert rules to notification channels (many-to-many)
-- ============================================================
CREATE TABLE alert_notifications (
    alert_rule_id INTEGER REFERENCES alert_rules(id),
    channel_id INTEGER REFERENCES notification_channels(id),
    PRIMARY KEY (alert_rule_id, channel_id)
);

-- ============================================================
-- Alert history — every time an alert fires or resolves
-- ============================================================
CREATE TABLE alert_events (
    id SERIAL PRIMARY KEY,
    alert_rule_id INTEGER REFERENCES alert_rules(id),
    state VARCHAR(20) NOT NULL,    -- firing, resolved
    value DECIMAL(10,4),           -- the metric value that triggered it
    fired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- ============================================================
-- Metric metadata — catalog of known metrics
-- ============================================================
CREATE TABLE metric_catalog (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    unit VARCHAR(50),              -- percent, bytes, seconds, count
    metric_type VARCHAR(50),       -- gauge, counter, histogram
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Dashboard definitions
-- ============================================================
CREATE TABLE dashboards (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    panels JSONB NOT NULL DEFAULT '[]',  -- array of panel configs
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Seed data
-- ============================================================

-- Metric catalog
INSERT INTO metric_catalog (name, description, unit, metric_type) VALUES
    ('cpu_usage', 'CPU utilization percentage', 'percent', 'gauge'),
    ('memory_usage', 'Memory utilization percentage', 'percent', 'gauge'),
    ('disk_usage', 'Disk utilization percentage', 'percent', 'gauge'),
    ('http_requests_total', 'Total HTTP requests served', 'count', 'counter'),
    ('http_request_duration_seconds', 'HTTP request latency', 'seconds', 'histogram'),
    ('error_rate', 'Percentage of requests returning errors', 'percent', 'gauge'),
    ('active_connections', 'Number of active database connections', 'count', 'gauge'),
    ('queue_depth', 'Number of messages waiting in queue', 'count', 'gauge');

-- Notification channels
INSERT INTO notification_channels (name, channel_type, config) VALUES
    ('Ops Slack', 'slack', '{"webhook_url": "https://hooks.slack.com/example", "channel": "#ops-alerts"}'),
    ('On-Call Email', 'email', '{"to": "oncall@example.com"}'),
    ('Critical PagerDuty', 'pagerduty', '{"service_key": "pd-example-key", "severity": "critical"}');

-- Alert rules
INSERT INTO alert_rules (name, query, threshold, operator, duration_seconds, severity) VALUES
    ('High CPU', 'avg(cpu_usage)', 90.0, '>', 300, 'critical'),
    ('High Memory', 'avg(memory_usage)', 85.0, '>', 300, 'warning'),
    ('High Error Rate', 'avg(error_rate)', 5.0, '>', 60, 'critical'),
    ('Disk Almost Full', 'max(disk_usage)', 90.0, '>', 0, 'critical'),
    ('Slow Responses', 'avg(http_request_duration_seconds)', 2.0, '>', 300, 'warning'),
    ('Queue Backing Up', 'max(queue_depth)', 1000, '>', 120, 'warning');

-- Link alerts to channels
INSERT INTO alert_notifications (alert_rule_id, channel_id) VALUES
    (1, 1), (1, 3),   -- High CPU → Slack + PagerDuty
    (2, 1),             -- High Memory → Slack
    (3, 1), (3, 3),   -- High Error Rate → Slack + PagerDuty
    (4, 1), (4, 2),   -- Disk Full → Slack + Email
    (5, 1),             -- Slow Responses → Slack
    (6, 1);             -- Queue Backing Up → Slack

-- Sample dashboard
INSERT INTO dashboards (name, description, panels) VALUES
    ('Server Health', 'Overview of server resource usage', '[
        {"title": "CPU Usage", "query": "avg(cpu_usage)", "type": "timeseries"},
        {"title": "Memory Usage", "query": "avg(memory_usage)", "type": "timeseries"},
        {"title": "Disk Usage", "query": "avg(disk_usage)", "type": "gauge"},
        {"title": "Error Rate", "query": "avg(error_rate)", "type": "timeseries"}
    ]');

-- Indexes
CREATE INDEX idx_alert_events_rule ON alert_events(alert_rule_id);
CREATE INDEX idx_alert_events_fired ON alert_events(fired_at);
CREATE INDEX idx_metric_catalog_name ON metric_catalog(name);
