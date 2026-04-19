-- Scaling Reads Demo Database
-- This schema demonstrates read scaling challenges and solutions

-- Users table (will have 100k+ rows for realistic demos)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(100) NOT NULL,
    display_name VARCHAR(200),
    bio TEXT,
    profile_image_url VARCHAR(500),
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Posts table (normalized - requires joins)
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    image_url VARCHAR(500),
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Comments table
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id),
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Likes table
CREATE TABLE likes (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id),
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
);

-- Followers table
CREATE TABLE followers (
    id SERIAL PRIMARY KEY,
    follower_id INTEGER REFERENCES users(id),
    following_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

-- Denormalized feed table (for comparison)
CREATE TABLE feed_items (
    id SERIAL PRIMARY KEY,
    viewer_user_id INTEGER NOT NULL,
    post_id INTEGER NOT NULL,
    author_user_id INTEGER NOT NULL,
    author_username VARCHAR(100) NOT NULL,
    author_display_name VARCHAR(200),
    author_profile_image VARCHAR(500),
    post_content TEXT NOT NULL,
    post_image_url VARCHAR(500),
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL
);

-- Products table for e-commerce examples
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    brand VARCHAR(100),
    stock_quantity INTEGER DEFAULT 0,
    rating_sum INTEGER DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product reviews
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    user_id INTEGER REFERENCES users(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    content TEXT,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- URL shortener table (for Bitly-like examples)
CREATE TABLE short_urls (
    id SERIAL PRIMARY KEY,
    short_code VARCHAR(10) UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
    click_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Materialized view for product ratings (will create later in notebooks)
-- CREATE MATERIALIZED VIEW product_ratings AS ...

-- Generate sample users
-- We use 20,000 so sequential scans in the "without index" demos are
-- slow enough to clearly see the difference after adding indexes.
INSERT INTO users (email, username, display_name, bio, follower_count, following_count, post_count)
SELECT 
    'user' || i || '@example.com',
    'user' || i,
    'User ' || i,
    'Bio for user ' || i,
    floor(random() * 10000)::int,
    floor(random() * 500)::int,
    floor(random() * 100)::int
FROM generate_series(1, 20000) AS i;

-- Generate sample posts (~50k to make feed/join queries meaningful)
INSERT INTO posts (user_id, content, like_count, comment_count, created_at)
SELECT 
    (floor(random() * 20000) + 1)::int,
    'Post content ' || i || '. This is a sample post with some text.',
    floor(random() * 1000)::int,
    floor(random() * 50)::int,
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 50000) AS i;

-- Generate sample comments
INSERT INTO comments (post_id, user_id, content, created_at)
SELECT 
    (floor(random() * 50000) + 1)::int,
    (floor(random() * 20000) + 1)::int,
    'Comment ' || i,
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 30000) AS i;

-- Generate sample products
INSERT INTO products (name, description, price, category, brand, stock_quantity, rating_sum, rating_count, view_count)
SELECT 
    'Product ' || i,
    'Description for product ' || i || '. High quality item.',
    (random() * 500 + 10)::decimal(10,2),
    (ARRAY['Electronics', 'Clothing', 'Home', 'Sports', 'Books'])[floor(random() * 5 + 1)::int],
    'Brand ' || (floor(random() * 20) + 1)::int,
    floor(random() * 1000)::int,
    floor(random() * 500)::int,
    floor(random() * 100 + 1)::int,
    floor(random() * 100000)::int
FROM generate_series(1, 5000) AS i;

-- Generate sample reviews
INSERT INTO reviews (product_id, user_id, rating, title, content, created_at)
SELECT 
    (floor(random() * 5000) + 1)::int,
    (floor(random() * 20000) + 1)::int,
    floor(random() * 5 + 1)::int,
    'Review title ' || i,
    'Review content ' || i,
    NOW() - (random() * interval '90 days')
FROM generate_series(1, 20000) AS i;

-- Generate sample short URLs
INSERT INTO short_urls (short_code, original_url, click_count, created_at)
SELECT 
    'abc' || i,
    'https://example.com/very/long/url/path/' || i,
    floor(random() * 1000000)::int,
    NOW() - (random() * interval '365 days')
FROM generate_series(1, 1000) AS i;

-- Generate followers
INSERT INTO followers (follower_id, following_id)
SELECT DISTINCT
    (floor(random() * 20000) + 1)::int,
    (floor(random() * 20000) + 1)::int
FROM generate_series(1, 10000) AS i
ON CONFLICT DO NOTHING;

-- Table to track cache performance metrics
CREATE TABLE cache_metrics (
    id SERIAL PRIMARY KEY,
    cache_key VARCHAR(255) NOT NULL,
    hit_count INTEGER DEFAULT 0,
    miss_count INTEGER DEFAULT 0,
    avg_response_ms DECIMAL(10,2),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
