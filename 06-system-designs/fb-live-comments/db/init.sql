-- FB Live Comments Lab - Database Schema
-- Models the core entities: users, live videos, and comments

-- ============================================================
-- Tables
-- ============================================================

-- Users table (viewers and broadcasters)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Live videos table
CREATE TABLE live_videos (
    id SERIAL PRIMARY KEY,
    broadcaster_id INTEGER REFERENCES users(id),
    title VARCHAR(500) NOT NULL,
    is_live BOOLEAN DEFAULT TRUE,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP
);

-- Comments table
-- Uses a BIGSERIAL id so we can use it as a cursor for pagination
CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    live_video_id INTEGER NOT NULL REFERENCES live_videos(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for the queries we'll run in the notebooks
-- Cursor-based pagination: fetch comments for a video, ordered by id
CREATE INDEX idx_comments_video_id ON comments(live_video_id, id DESC);
-- Lookup comments by creation time (for time-based catch-up queries)
CREATE INDEX idx_comments_video_created ON comments(live_video_id, created_at DESC);

-- ============================================================
-- Seed data
-- ============================================================

-- 50 sample users
INSERT INTO users (username, display_name)
SELECT
    'user' || i,
    'User ' || i
FROM generate_series(1, 50) AS i;

-- 3 live videos
INSERT INTO live_videos (broadcaster_id, title, is_live, started_at) VALUES
    (1, 'Cooking Live: Making Pasta from Scratch', TRUE, NOW() - interval '30 minutes'),
    (2, 'Gaming Stream: Speedrun Challenge', TRUE, NOW() - interval '1 hour'),
    (3, 'Q&A Session: Ask Me Anything', TRUE, NOW() - interval '15 minutes');

-- 500 sample comments spread across the 3 videos
-- Comments are inserted with staggered timestamps to simulate a real feed
INSERT INTO comments (live_video_id, user_id, message, created_at)
SELECT
    -- distribute across 3 videos (more comments on video 1)
    CASE
        WHEN i % 10 < 5 THEN 1
        WHEN i % 10 < 8 THEN 2
        ELSE 3
    END,
    -- random user
    (floor(random() * 50) + 1)::int,
    -- varied messages
    (ARRAY[
        'Great stream! 🔥',
        'First time here, love it!',
        'Can you explain that again?',
        'LOL 😂',
        'This is amazing!',
        'Hello from Brazil! 🇧🇷',
        'How long have you been doing this?',
        'Wow, didn''t expect that!',
        'Subscribed! Keep going!',
        'Can you say hi to me?',
        'This is so cool!',
        'I have a question...',
        'Best stream ever!',
        'Good vibes only ✌️',
        'Love the content!'
    ])[floor(random() * 15 + 1)::int],
    -- stagger timestamps so comments feel realistic
    NOW() - interval '30 minutes' + (i * interval '3.6 seconds')
FROM generate_series(1, 500) AS i;
