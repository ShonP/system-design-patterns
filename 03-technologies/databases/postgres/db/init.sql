-- ============================================================
-- PostgreSQL Deep Dive Lab — Social Media Platform Schema
-- ============================================================
-- A social media platform with users, posts, comments, follows, and likes.
-- Generates enough data (~500K+ rows) to demonstrate meaningful
-- performance differences between indexed and unindexed queries.
-- ============================================================

-- ============================================================
-- Schema
-- ============================================================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    title VARCHAR(255),
    content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'published',  -- draft, published, archived
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE follows (
    follower_id INTEGER NOT NULL REFERENCES users(id),
    following_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, following_id)
);

CREATE TABLE likes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    post_id INTEGER REFERENCES posts(id),
    comment_id INTEGER REFERENCES comments(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- A user can only like a post or comment once
    CONSTRAINT unique_post_like UNIQUE (user_id, post_id),
    CONSTRAINT like_target CHECK (
        (post_id IS NOT NULL AND comment_id IS NULL) OR
        (post_id IS NULL AND comment_id IS NOT NULL)
    )
);

CREATE TABLE direct_messages (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES users(id),
    receiver_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Seed Data — generated with generate_series for speed
-- ============================================================

-- 5,000 users
INSERT INTO users (username, email, display_name, bio, is_verified, follower_count, following_count, created_at, last_login_at)
SELECT
    'user_' || i,
    'user_' || i || '@example.com',
    'User ' || i,
    CASE (i % 5)
        WHEN 0 THEN 'Software engineer who loves building things.'
        WHEN 1 THEN 'Designer and photographer. Travel enthusiast.'
        WHEN 2 THEN 'Data scientist. ML and AI researcher.'
        WHEN 3 THEN 'Product manager. Startup advisor.'
        WHEN 4 THEN 'Student learning to code. Open source contributor.'
    END,
    (i % 50 = 0),  -- 2% of users are verified
    floor(random() * 5000)::int,
    floor(random() * 500)::int,
    NOW() - (random() * interval '730 days'),  -- created within last 2 years
    NOW() - (random() * interval '30 days')    -- last login within 30 days
FROM generate_series(1, 5000) AS i;

-- 100,000 posts (20 per user on average)
INSERT INTO posts (user_id, title, content, status, like_count, comment_count, view_count, created_at, updated_at)
SELECT
    (floor(random() * 5000) + 1)::int,
    'Post title #' || i || ' — ' ||
    CASE (i % 8)
        WHEN 0 THEN 'Thoughts on system design'
        WHEN 1 THEN 'My weekend project'
        WHEN 2 THEN 'Learning PostgreSQL'
        WHEN 3 THEN 'Book review'
        WHEN 4 THEN 'Hot take on microservices'
        WHEN 5 THEN 'Tips for new developers'
        WHEN 6 THEN 'Conference recap'
        WHEN 7 THEN 'Open source update'
    END,
    'This is the content of post #' || i || '. ' ||
    CASE (i % 4)
        WHEN 0 THEN 'In this post I share my thoughts on building scalable systems.'
        WHEN 1 THEN 'Here are some lessons I learned while working on a distributed system.'
        WHEN 2 THEN 'Let me walk you through my approach to solving this problem.'
        WHEN 3 THEN 'I have been experimenting with new technologies and here is what I found.'
    END,
    (ARRAY['published', 'published', 'published', 'draft', 'archived'])[floor(random() * 5 + 1)::int],
    floor(random() * 500)::int,
    floor(random() * 50)::int,
    floor(random() * 10000)::int,
    NOW() - (random() * interval '365 days'),
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 100000) AS i;

-- 200,000 comments
INSERT INTO comments (post_id, user_id, content, like_count, created_at)
SELECT
    (floor(random() * 100000) + 1)::int,
    (floor(random() * 5000) + 1)::int,
    CASE (i % 6)
        WHEN 0 THEN 'Great post! Thanks for sharing.'
        WHEN 1 THEN 'I disagree — have you considered the tradeoffs?'
        WHEN 2 THEN 'This is exactly what I needed to hear today.'
        WHEN 3 THEN 'Can you share more details about the implementation?'
        WHEN 4 THEN 'Bookmarking this for later reference.'
        WHEN 5 THEN 'Interesting perspective. I had a similar experience.'
    END,
    floor(random() * 20)::int,
    NOW() - (random() * interval '365 days')
FROM generate_series(1, 200000) AS i;

-- 30,000 follow relationships
INSERT INTO follows (follower_id, following_id, created_at)
SELECT DISTINCT ON (a, b) a, b, NOW() - (random() * interval '365 days')
FROM (
    SELECT
        (floor(random() * 5000) + 1)::int AS a,
        (floor(random() * 5000) + 1)::int AS b
    FROM generate_series(1, 40000)
) sub
WHERE a != b
ON CONFLICT DO NOTHING;

-- 300,000 post likes
INSERT INTO likes (user_id, post_id, created_at)
SELECT DISTINCT ON (u, p) u, p, NOW() - (random() * interval '365 days')
FROM (
    SELECT
        (floor(random() * 5000) + 1)::int AS u,
        (floor(random() * 100000) + 1)::int AS p
    FROM generate_series(1, 400000)
) sub
ON CONFLICT DO NOTHING;

-- 50,000 direct messages
INSERT INTO direct_messages (sender_id, receiver_id, content, is_read, created_at)
SELECT
    (floor(random() * 5000) + 1)::int,
    (floor(random() * 5000) + 1)::int,
    'Message #' || i || ': ' ||
    CASE (i % 4)
        WHEN 0 THEN 'Hey! How are you doing?'
        WHEN 1 THEN 'Did you see the latest post?'
        WHEN 2 THEN 'Let us connect and discuss the project.'
        WHEN 3 THEN 'Thanks for the follow back!'
    END,
    (random() > 0.3),
    NOW() - (random() * interval '90 days')
FROM generate_series(1, 50000) AS i;

-- ============================================================
-- NOTE: We intentionally do NOT create indexes here (except PKs
-- and unique constraints). The notebooks will create indexes
-- to demonstrate the before/after performance difference.
-- ============================================================

-- Run ANALYZE so the query planner has accurate statistics
ANALYZE;
