-- Time-Series Databases Lab — Init Script
-- Creates a server-monitoring scenario with TimescaleDB hypertables

-- Enable TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- ============================================================
-- Raw metrics table (the core hypertable)
-- ============================================================
CREATE TABLE metrics (
    time        TIMESTAMPTZ NOT NULL,
    host        TEXT        NOT NULL,
    region      TEXT        NOT NULL,
    metric_name TEXT        NOT NULL,
    value       DOUBLE PRECISION NOT NULL
);

-- Convert to a hypertable — TimescaleDB automatically partitions by time
SELECT create_hypertable('metrics', 'time');

-- Index for common query patterns: filter by host + metric, then scan by time
CREATE INDEX idx_metrics_host_metric ON metrics (host, metric_name, time DESC);

-- ============================================================
-- Seed data — 7 days of 30-second metrics for 10 hosts
-- Metrics: cpu_usage, memory_usage, disk_io, network_rx
-- ============================================================
INSERT INTO metrics (time, host, region, metric_name, value)
SELECT
    ts,
    'server-' || host_id,
    CASE WHEN host_id <= 5 THEN 'us-west' ELSE 'us-east' END,
    metric,
    CASE metric
        -- cpu: baseline 30-60 % with daily wave + noise
        WHEN 'cpu_usage' THEN
            40 + 20 * sin(extract(epoch FROM ts) / 43200 * pi())
            + (random() * 10 - 5)
            + (host_id * 2)
        -- memory: slowly drifts up then resets (simulates leak / restart)
        WHEN 'memory_usage' THEN
            50 + 30 * (extract(epoch FROM ts)::bigint % 86400) / 86400.0
            + (random() * 5)
        -- disk: spiky
        WHEN 'disk_io' THEN
            greatest(0, 200 + 600 * random() * (CASE WHEN random() < 0.1 THEN 5 ELSE 1 END))
        -- network: follows cpu loosely
        WHEN 'network_rx' THEN
            greatest(0,
                1000 + 500 * sin(extract(epoch FROM ts) / 43200 * pi())
                + random() * 300 - 150)
    END
FROM
    generate_series(
        now() - interval '7 days',
        now(),
        interval '30 seconds'
    ) AS ts,
    generate_series(1, 10) AS host_id,
    unnest(ARRAY['cpu_usage', 'memory_usage', 'disk_io', 'network_rx']) AS metric;

-- ============================================================
-- A plain (non-hypertable) copy for performance comparison
-- ============================================================
CREATE TABLE metrics_plain (
    time        TIMESTAMPTZ      NOT NULL,
    host        TEXT             NOT NULL,
    region      TEXT             NOT NULL,
    metric_name TEXT             NOT NULL,
    value       DOUBLE PRECISION NOT NULL
);

INSERT INTO metrics_plain SELECT * FROM metrics;
CREATE INDEX idx_plain_host_metric ON metrics_plain (host, metric_name, time DESC);
