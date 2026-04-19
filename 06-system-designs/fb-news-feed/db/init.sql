-- Facebook News Feed Lab — Database Schema
-- Models users, follows, posts, and precomputed feeds

-- ============================================================
-- Core tables
-- ============================================================

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Follow table (uni-directional: follower → followee)
-- This is the "social graph" stored in a relational table.
-- Think of each row as a directed edge in a graph.
CREATE TABLE follows (
    follower_id INTEGER REFERENCES users(id),
    followee_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followee_id)
);

-- Index to quickly answer "who follows user X?"
CREATE INDEX idx_follows_followee ON follows(followee_id);

-- Posts table
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    author_id INTEGER REFERENCES users(id) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index to quickly get "all posts by user X, newest first"
CREATE INDEX idx_posts_author_time ON posts(author_id, created_at DESC);

-- Precomputed feed table (fan-out on write materialises feed here)
-- Each row = one post that should appear in one user's feed.
CREATE TABLE precomputed_feed (
    user_id INTEGER REFERENCES users(id),
    post_id INTEGER REFERENCES posts(id),
    post_author_id INTEGER REFERENCES users(id),
    post_created_at TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, post_id)
);

-- Fast lookup: "give me user X's feed, newest first"
CREATE INDEX idx_feed_user_time ON precomputed_feed(user_id, post_created_at DESC);

-- ============================================================
-- Seed data — 50 users, follow relationships, and posts
-- ============================================================

-- Create 50 regular users + 3 "celebrity" users
INSERT INTO users (username, display_name)
SELECT
    'user' || i,
    'User ' || i
FROM generate_series(1, 50) AS i;

INSERT INTO users (username, display_name) VALUES
    ('celebrity_alice', 'Alice (Celebrity)'),
    ('celebrity_bob',   'Bob (Celebrity)'),
    ('celebrity_carol', 'Carol (Celebrity)');

-- Each regular user follows 5–15 random other users
-- (deterministic via modular arithmetic so results are reproducible)
INSERT INTO follows (follower_id, followee_id)
SELECT DISTINCT
    follower,
    followee
FROM (
    SELECT
        u.id AS follower,
        -- pick a pseudo-random followee using modular arithmetic
        ((u.id * prime + shift) % 50) + 1 AS followee
    FROM users u
    CROSS JOIN (
        VALUES (7,3),(13,11),(19,17),(29,5),(37,23),(41,2),(43,31),(47,13),(3,7),(11,29)
    ) AS params(prime, shift)
    WHERE u.id <= 50
) sub
WHERE follower <> followee;

-- Every regular user follows at least one celebrity
INSERT INTO follows (follower_id, followee_id)
SELECT u.id, 51 FROM users u WHERE u.id <= 50
ON CONFLICT DO NOTHING;

INSERT INTO follows (follower_id, followee_id)
SELECT u.id, 52 FROM users u WHERE u.id <= 25
ON CONFLICT DO NOTHING;

INSERT INTO follows (follower_id, followee_id)
SELECT u.id, 53 FROM users u WHERE u.id BETWEEN 26 AND 50
ON CONFLICT DO NOTHING;

-- Create posts — regular users get 3 posts each, celebrities get 10
INSERT INTO posts (author_id, content, created_at)
SELECT
    u.id,
    'Post ' || p || ' from ' || u.display_name || '. Hello world!',
    NOW() - ((50 - u.id) * 3 + p || ' hours')::interval
FROM users u
CROSS JOIN generate_series(1, 3) AS p
WHERE u.id <= 50;

INSERT INTO posts (author_id, content, created_at)
SELECT
    u.id,
    'Celebrity post ' || p || ' from ' || u.display_name || ' — big announcement!',
    NOW() - (p || ' hours')::interval
FROM users u
CROSS JOIN generate_series(1, 10) AS p
WHERE u.id > 50;

-- Pre-populate the precomputed_feed for all users based on who they follow
INSERT INTO precomputed_feed (user_id, post_id, post_author_id, post_created_at)
SELECT
    f.follower_id,
    p.id,
    p.author_id,
    p.created_at
FROM follows f
JOIN posts p ON p.author_id = f.followee_id;
