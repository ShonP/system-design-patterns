-- =============================================================
-- Data Modeling Lab — Social Media Demo Database
-- Demonstrates relational modeling, normalization, indexing,
-- denormalization trade-offs, and schema evolution patterns.
-- =============================================================

-- =====================
-- Core Normalized Tables
-- =====================

-- Users: each person on the platform
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Posts: content created by users (1:N with users)
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Comments: replies to posts (belongs to a post AND a user)
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Likes: many-to-many between users and posts
-- Composite unique constraint prevents double-liking
CREATE TABLE likes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    post_id INTEGER NOT NULL REFERENCES posts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, post_id)
);

-- Follows: many-to-many self-referencing relationship on users
CREATE TABLE follows (
    follower_id INTEGER NOT NULL REFERENCES users(id),
    following_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- Tags: categories/hashtags for posts
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

-- Post-Tag junction table (many-to-many)
CREATE TABLE post_tags (
    post_id INTEGER NOT NULL REFERENCES posts(id),
    tag_id INTEGER NOT NULL REFERENCES tags(id),
    PRIMARY KEY (post_id, tag_id)
);

-- ============================================================
-- Denormalized table (for comparison in Notebook 2)
-- Stores pre-computed counts alongside posts
-- ============================================================
CREATE TABLE posts_denormalized (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    username VARCHAR(50) NOT NULL,
    user_display_name VARCHAR(100),
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes — support common access patterns
-- ============================================================
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_likes_post_id ON likes(post_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- ============================================================
-- Seed Data
-- ============================================================

-- 50 users
INSERT INTO users (username, email, display_name, bio)
SELECT
    'user_' || i,
    'user_' || i || '@example.com',
    'User ' || i,
    CASE (i % 5)
        WHEN 0 THEN 'Loves hiking and photography'
        WHEN 1 THEN 'Software engineer by day, musician by night'
        WHEN 2 THEN 'Avid reader and coffee enthusiast'
        WHEN 3 THEN 'Exploring the world one city at a time'
        WHEN 4 THEN 'Foodie, traveler, storyteller'
    END
FROM generate_series(1, 50) AS i;

-- 10 tags
INSERT INTO tags (name) VALUES
    ('tech'), ('travel'), ('food'), ('music'), ('fitness'),
    ('photography'), ('books'), ('gaming'), ('nature'), ('coding');

-- 200 posts spread across users
INSERT INTO posts (user_id, content, created_at)
SELECT
    (floor(random() * 50) + 1)::int,
    CASE (i % 6)
        WHEN 0 THEN 'Just shipped a new feature at work! Feeling productive 🚀'
        WHEN 1 THEN 'Beautiful sunset from my balcony today 🌅'
        WHEN 2 THEN 'Made homemade pasta for the first time — turned out amazing 🍝'
        WHEN 3 THEN 'Currently reading "Designing Data-Intensive Applications" — highly recommend 📚'
        WHEN 4 THEN 'Morning run done! 5K in 25 minutes, new personal best 🏃'
        WHEN 5 THEN 'Working on a side project this weekend. Building a URL shortener!'
    END,
    NOW() - (random() * interval '90 days')
FROM generate_series(1, 200) AS i;

-- Tag posts randomly (each post gets 1-3 tags)
INSERT INTO post_tags (post_id, tag_id)
SELECT DISTINCT
    post_id,
    tag_id
FROM (
    SELECT
        (floor(random() * 200) + 1)::int AS post_id,
        (floor(random() * 10) + 1)::int AS tag_id
    FROM generate_series(1, 400)
) sub
ON CONFLICT DO NOTHING;

-- 500 comments across posts
INSERT INTO comments (post_id, user_id, content, created_at)
SELECT
    (floor(random() * 200) + 1)::int,
    (floor(random() * 50) + 1)::int,
    CASE (i % 5)
        WHEN 0 THEN 'Great post! Thanks for sharing.'
        WHEN 1 THEN 'I totally agree with this!'
        WHEN 2 THEN 'Interesting perspective, never thought of it that way.'
        WHEN 3 THEN 'This is awesome! Keep it up 👏'
        WHEN 4 THEN 'Can you share more details about this?'
    END,
    NOW() - (random() * interval '60 days')
FROM generate_series(1, 500) AS i;

-- 1000 likes spread across users and posts
INSERT INTO likes (user_id, post_id, created_at)
SELECT DISTINCT ON (user_id, post_id)
    user_id,
    post_id,
    NOW() - (random() * interval '60 days')
FROM (
    SELECT
        (floor(random() * 50) + 1)::int AS user_id,
        (floor(random() * 200) + 1)::int AS post_id
    FROM generate_series(1, 1500)
) sub
ON CONFLICT DO NOTHING;

-- Follow relationships (each user follows 5-15 others)
INSERT INTO follows (follower_id, following_id, created_at)
SELECT DISTINCT ON (follower_id, following_id)
    follower_id,
    following_id,
    NOW() - (random() * interval '90 days')
FROM (
    SELECT
        (floor(random() * 50) + 1)::int AS follower_id,
        (floor(random() * 50) + 1)::int AS following_id
    FROM generate_series(1, 600)
) sub
WHERE follower_id != following_id
ON CONFLICT DO NOTHING;

-- Populate the denormalized posts table from the normalized data
INSERT INTO posts_denormalized (id, user_id, username, user_display_name, content, like_count, comment_count, created_at)
SELECT
    p.id,
    p.user_id,
    u.username,
    u.display_name,
    p.content,
    COALESCE(l.like_count, 0),
    COALESCE(c.comment_count, 0),
    p.created_at
FROM posts p
JOIN users u ON p.user_id = u.id
LEFT JOIN (SELECT post_id, COUNT(*) AS like_count FROM likes GROUP BY post_id) l ON l.post_id = p.id
LEFT JOIN (SELECT post_id, COUNT(*) AS comment_count FROM comments GROUP BY post_id) c ON c.post_id = p.id;
