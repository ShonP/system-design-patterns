-- Numbers to Know Lab Database
-- Data for benchmarking queries and estimation exercises

-- Simple key-value table for benchmarking reads
CREATE TABLE benchmark_kv (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table (for estimation exercises)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events table (for throughput/QPS exercises)
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    event_type VARCHAR(50) NOT NULL,
    payload TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Seed data
-- ============================================================

-- 10K key-value pairs for benchmarking
INSERT INTO benchmark_kv (key, value)
SELECT
    'key:' || i,
    'value_' || i || '_' || repeat('x', 100)
FROM generate_series(1, 10000) AS i;

-- 1000 users
INSERT INTO users (username, email, bio)
SELECT
    'user_' || i,
    'user' || i || '@example.com',
    'This is the bio for user ' || i || '. ' || repeat('Lorem ipsum ', 5)
FROM generate_series(1, 1000) AS i;

-- 50K events (for throughput testing)
INSERT INTO events (user_id, event_type, payload, created_at)
SELECT
    (floor(random() * 1000) + 1)::int,
    (ARRAY['page_view', 'click', 'purchase', 'signup', 'logout'])[floor(random() * 5 + 1)::int],
    '{"action": "event_' || i || '", "data": "' || repeat('x', 50) || '"}',
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 50000) AS i;

-- Indexes
CREATE INDEX idx_benchmark_kv_key ON benchmark_kv(key);
CREATE INDEX idx_events_user ON events(user_id);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_created ON events(created_at);
