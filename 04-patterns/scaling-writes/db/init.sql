-- Scaling Writes Demo Database
-- This schema demonstrates write scaling challenges and solutions

-- Events table for high-volume writes (analytics)
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    user_id INTEGER NOT NULL,
    payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Posts table (social media example)
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Post metrics (high-frequency counter updates)
CREATE TABLE post_metrics (
    post_id INTEGER PRIMARY KEY,
    like_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sharded counters (for hot key demo)
CREATE TABLE sharded_counters (
    post_id INTEGER NOT NULL,
    shard_id INTEGER NOT NULL,
    count INTEGER DEFAULT 0,
    PRIMARY KEY (post_id, shard_id)
);

-- Location updates (Uber/Strava example)
CREATE TABLE location_updates (
    id SERIAL PRIMARY KEY,
    driver_id INTEGER NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Batch writes staging table
CREATE TABLE write_batch (
    id SERIAL PRIMARY KEY,
    batch_id UUID NOT NULL,
    operation VARCHAR(20) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    data JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Simulated shards tracking
CREATE TABLE shard_stats (
    shard_id INTEGER PRIMARY KEY,
    write_count INTEGER DEFAULT 0,
    last_write TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initialize shard stats
INSERT INTO shard_stats (shard_id, write_count)
SELECT i, 0 FROM generate_series(0, 7) AS i;

-- Create some initial posts for demos
INSERT INTO posts (user_id, content)
SELECT 
    (floor(random() * 1000) + 1)::int,
    'Sample post content ' || i
FROM generate_series(1, 100) AS i;

-- Initialize post metrics
INSERT INTO post_metrics (post_id, like_count, view_count)
SELECT id, 0, 0 FROM posts;

-- Function to simulate write latency measurement
CREATE OR REPLACE FUNCTION measure_write_time()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Indexes (we'll demonstrate enabling/disabling for write optimization)
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_created ON events(created_at);
CREATE INDEX idx_location_driver ON location_updates(driver_id);
CREATE INDEX idx_location_time ON location_updates(timestamp);
