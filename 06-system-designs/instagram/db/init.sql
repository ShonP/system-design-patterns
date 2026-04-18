-- Instagram Lab — Database Schema
-- Models users, follows, posts, media, stories, likes, and precomputed feeds

-- ============================================================
-- Core tables
-- ============================================================

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    bio TEXT DEFAULT '',
    profile_pic_url TEXT DEFAULT '',
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    is_celebrity BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Follow table (uni-directional: follower → followee)
CREATE TABLE follows (
    follower_id INTEGER REFERENCES users(id),
    followee_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followee_id)
);

-- Index to quickly answer "who follows user X?"
CREATE INDEX idx_follows_followee ON follows(followee_id);

-- Posts table — every post has a caption and links to media
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    author_id INTEGER REFERENCES users(id) NOT NULL,
    caption TEXT DEFAULT '',
    media_type VARCHAR(10) NOT NULL DEFAULT 'photo',  -- 'photo' or 'video'
    media_key TEXT NOT NULL,                           -- S3/MinIO object key
    media_upload_status VARCHAR(20) DEFAULT 'complete', -- 'pending' or 'complete'
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index to quickly get "all posts by user X, newest first"
CREATE INDEX idx_posts_author_time ON posts(author_id, created_at DESC);

-- Precomputed feed table (fan-out on write materialises feed here)
CREATE TABLE precomputed_feed (
    user_id INTEGER REFERENCES users(id),
    post_id INTEGER REFERENCES posts(id),
    post_author_id INTEGER REFERENCES users(id),
    post_created_at TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, post_id)
);

-- Fast lookup: "give me user X's feed, newest first"
CREATE INDEX idx_feed_user_time ON precomputed_feed(user_id, post_created_at DESC);

-- Likes table
CREATE TABLE likes (
    user_id INTEGER REFERENCES users(id),
    post_id INTEGER REFERENCES posts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id)
);

-- Comments table
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) NOT NULL,
    author_id INTEGER REFERENCES users(id) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comments_post ON comments(post_id, created_at DESC);

-- Stories table (ephemeral content — disappears after 24 hours)
CREATE TABLE stories (
    id SERIAL PRIMARY KEY,
    author_id INTEGER REFERENCES users(id) NOT NULL,
    media_key TEXT NOT NULL,           -- S3/MinIO object key
    media_type VARCHAR(10) DEFAULT 'photo',
    expires_at TIMESTAMP NOT NULL,     -- created_at + 24 hours
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stories_author ON stories(author_id, created_at DESC);
CREATE INDEX idx_stories_expiry ON stories(expires_at);

-- Story views — tracks who has seen a story
CREATE TABLE story_views (
    story_id INTEGER REFERENCES stories(id),
    viewer_id INTEGER REFERENCES users(id),
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (story_id, viewer_id)
);

-- Explore/recommendation — tracks user interactions for scoring
CREATE TABLE user_interactions (
    user_id INTEGER REFERENCES users(id),
    post_id INTEGER REFERENCES posts(id),
    interaction_type VARCHAR(20) NOT NULL,  -- 'like', 'comment', 'view', 'save'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_interactions_user ON user_interactions(user_id, created_at DESC);
CREATE INDEX idx_interactions_post ON user_interactions(post_id);

-- ============================================================
-- Seed data
-- ============================================================

-- Create 50 regular users + 3 "celebrity" users
INSERT INTO users (username, display_name, bio, follower_count, following_count)
SELECT
    'user' || i,
    'User ' || i,
    'Just a regular user who loves sharing photos!',
    floor(random() * 500 + 10)::int,
    floor(random() * 200 + 5)::int
FROM generate_series(1, 50) AS i;

INSERT INTO users (username, display_name, bio, follower_count, following_count, is_celebrity) VALUES
    ('celeb_alice', 'Alice (Celebrity)', '📸 Photographer & Influencer', 1500000, 200, TRUE),
    ('celeb_bob',   'Bob (Celebrity)',   '🎵 Musician & Creator',       2000000, 150, TRUE),
    ('celeb_carol', 'Carol (Celebrity)', '🎬 Filmmaker & Traveler',     800000,  300, TRUE);

-- Each regular user follows 5–15 random other users
INSERT INTO follows (follower_id, followee_id)
SELECT DISTINCT
    follower,
    followee
FROM (
    SELECT
        u.id AS follower,
        ((u.id * prime + offset) % 50) + 1 AS followee
    FROM users u
    CROSS JOIN (
        VALUES (7,3),(13,11),(19,17),(29,5),(37,23),(41,2),(43,31),(47,13),(3,7),(11,29)
    ) AS params(prime, offset)
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
-- media_key points to where image would be stored in MinIO
INSERT INTO posts (author_id, caption, media_type, media_key, like_count, comment_count, created_at)
SELECT
    u.id,
    'Beautiful day! Post #' || p || ' from ' || u.display_name || ' 📸',
    'photo',
    'photos/user_' || u.id || '/post_' || p || '.jpg',
    floor(random() * 500 + 1)::int,
    floor(random() * 50)::int,
    NOW() - ((50 - u.id) * 3 + p || ' hours')::interval
FROM users u
CROSS JOIN generate_series(1, 3) AS p
WHERE u.id <= 50;

INSERT INTO posts (author_id, caption, media_type, media_key, like_count, comment_count, created_at)
SELECT
    u.id,
    'Celebrity post #' || p || ' from ' || u.display_name || ' — exciting news! 🌟',
    'photo',
    'photos/user_' || u.id || '/post_' || p || '.jpg',
    floor(random() * 100000 + 1000)::int,
    floor(random() * 5000)::int,
    NOW() - (p || ' hours')::interval
FROM users u
CROSS JOIN generate_series(1, 10) AS p
WHERE u.id > 50;

-- Pre-populate the precomputed_feed for all users
INSERT INTO precomputed_feed (user_id, post_id, post_author_id, post_created_at)
SELECT
    f.follower_id,
    p.id,
    p.author_id,
    p.created_at
FROM follows f
JOIN posts p ON p.author_id = f.followee_id;

-- Seed some stories (created within last 24 hours)
INSERT INTO stories (author_id, media_key, media_type, expires_at, created_at)
SELECT
    u.id,
    'stories/user_' || u.id || '/story_' || s || '.jpg',
    'photo',
    NOW() + ((24 - s * 2) || ' hours')::interval,
    NOW() - (s * 2 || ' hours')::interval
FROM users u
CROSS JOIN generate_series(1, 2) AS s
WHERE u.id <= 20;

-- Seed some likes and interactions for the explore algorithm
INSERT INTO likes (user_id, post_id, created_at)
SELECT
    (floor(random() * 50) + 1)::int,
    (floor(random() * 180) + 1)::int,
    NOW() - (random() * interval '7 days')
FROM generate_series(1, 500) AS i
ON CONFLICT DO NOTHING;

INSERT INTO user_interactions (user_id, post_id, interaction_type, created_at)
SELECT
    (floor(random() * 50) + 1)::int,
    (floor(random() * 180) + 1)::int,
    (ARRAY['like', 'view', 'comment', 'save'])[floor(random() * 4 + 1)::int],
    NOW() - (random() * interval '7 days')
FROM generate_series(1, 2000) AS i;
