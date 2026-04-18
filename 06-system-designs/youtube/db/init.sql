-- ============================================================
-- YouTube System Design - Database Schema & Seed Data
-- ============================================================

CREATE TABLE videos (
    id VARCHAR(12) PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    user_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'uploading',
    content_type VARCHAR(50),
    file_size_bytes BIGINT,
    duration_seconds INTEGER,
    raw_url VARCHAR(1000),
    manifest_url VARCHAR(1000),
    thumbnail_url VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE video_formats (
    id SERIAL PRIMARY KEY,
    video_id VARCHAR(12) NOT NULL REFERENCES videos(id),
    resolution VARCHAR(10) NOT NULL,
    codec VARCHAR(20) NOT NULL,
    container VARCHAR(10) NOT NULL,
    bitrate_kbps INTEGER,
    segment_count INTEGER,
    total_size_bytes BIGINT,
    manifest_url VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_videos_status ON videos(status);
CREATE INDEX idx_videos_user ON videos(user_id);
CREATE INDEX idx_video_formats_video ON video_formats(video_id);

-- Seed: a few completed videos for streaming lab
INSERT INTO videos (id, title, description, user_id, status, duration_seconds) VALUES
('dQw4w9WgXcQ', 'Rick Astley - Never Gonna Give You Up', 'The classic.', 1, 'ready', 212),
('jNQXAC9IVRw', 'Me at the zoo', 'The first video ever uploaded to YouTube.', 2, 'ready', 19),
('9bZkp7q19f0', 'PSY - GANGNAM STYLE', 'The most viewed video of its era.', 3, 'ready', 253);
