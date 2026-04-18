-- News Aggregator Lab — Database Schema
-- Models RSS feeds, articles, categories, users, and personalisation

-- ============================================================
-- Core tables
-- ============================================================

-- RSS / Atom feed sources the crawler checks periodically
CREATE TABLE feeds (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    url VARCHAR(500) UNIQUE NOT NULL,
    category VARCHAR(100),
    crawl_interval_minutes INTEGER DEFAULT 15,
    last_crawled_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Articles that the crawler has collected
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    feed_id INTEGER REFERENCES feeds(id),
    title VARCHAR(500) NOT NULL,
    url VARCHAR(500) UNIQUE NOT NULL,
    summary TEXT,
    author VARCHAR(200),
    published_at TIMESTAMP,
    crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- SHA-256 of normalised title+summary — used for deduplication
    content_hash VARCHAR(64),
    word_count INTEGER DEFAULT 0,
    -- how many different sources reported the same story
    source_count INTEGER DEFAULT 1
);

CREATE INDEX idx_articles_feed ON articles(feed_id);
CREATE INDEX idx_articles_published ON articles(published_at DESC);
CREATE INDEX idx_articles_hash ON articles(content_hash);

-- Topic categories (technology, sports, politics, …)
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL
);

-- Many-to-many: article ↔ category
CREATE TABLE article_categories (
    article_id INTEGER REFERENCES articles(id),
    category_id INTEGER REFERENCES categories(id),
    relevance_score DECIMAL(3,2) DEFAULT 1.00,
    PRIMARY KEY (article_id, category_id)
);

-- Groups of duplicate / near-duplicate articles
CREATE TABLE duplicate_groups (
    id SERIAL PRIMARY KEY,
    -- the "best" article chosen to represent the group
    canonical_article_id INTEGER REFERENCES articles(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE duplicate_members (
    group_id INTEGER REFERENCES duplicate_groups(id),
    article_id INTEGER REFERENCES articles(id),
    similarity_score DECIMAL(3,2),
    PRIMARY KEY (group_id, article_id)
);

-- Users of the news aggregator
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Which topics each user is interested in (weight = importance)
CREATE TABLE user_interests (
    user_id INTEGER REFERENCES users(id),
    category_id INTEGER REFERENCES categories(id),
    weight DECIMAL(3,2) DEFAULT 1.00,
    PRIMARY KEY (user_id, category_id)
);

-- Clicks, reads, bookmarks — used to learn preferences
CREATE TABLE user_interactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    article_id INTEGER REFERENCES articles(id),
    interaction_type VARCHAR(50) NOT NULL,  -- click, read, bookmark, share
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_interactions_user ON user_interactions(user_id);
CREATE INDEX idx_interactions_article ON user_interactions(article_id);

-- ============================================================
-- Seed data
-- ============================================================

-- Categories
INSERT INTO categories (name, slug) VALUES
    ('Technology',     'technology'),
    ('Science',        'science'),
    ('Business',       'business'),
    ('Sports',         'sports'),
    ('Entertainment',  'entertainment'),
    ('Health',         'health'),
    ('Politics',       'politics'),
    ('World',          'world');

-- RSS feed sources (real public RSS feeds for the notebook demos)
INSERT INTO feeds (name, url, category, crawl_interval_minutes) VALUES
    ('TechCrunch',           'https://techcrunch.com/feed/',                  'Technology',    15),
    ('Ars Technica',         'https://feeds.arstechnica.com/arstechnica/index','Technology',   15),
    ('NASA Breaking News',   'https://www.nasa.gov/news-release/feed/',       'Science',       30),
    ('BBC News World',       'http://feeds.bbci.co.uk/news/world/rss.xml',    'World',         10),
    ('ESPN Top Headlines',   'https://www.espn.com/espn/rss/news',            'Sports',        10),
    ('Reuters Business',     'https://www.reutersagency.com/feed/',            'Business',      10),
    ('NPR Health',           'https://feeds.npr.org/103537970/podcast.xml',    'Health',        30),
    ('Hacker News',          'https://hnrss.org/frontpage',                    'Technology',    10);

-- Sample articles (simulate what the crawler would have collected)
INSERT INTO articles (feed_id, title, url, summary, author, published_at, content_hash, word_count, source_count) VALUES
    -- Technology cluster — same story from two sources (duplicate)
    (1, 'OpenAI Releases GPT-5 With Reasoning Breakthrough',
        'https://techcrunch.com/2026/03/30/openai-gpt5',
        'OpenAI announced GPT-5 today, featuring a major leap in multi-step reasoning capabilities. The model can solve complex math and science problems with 95% accuracy.',
        'Sarah Chen', NOW() - INTERVAL '2 hours',
        'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6abcd', 350, 2),
    (2, 'GPT-5 Launches With Major Reasoning Improvements',
        'https://arstechnica.com/ai/2026/03/gpt5-reasoning',
        'OpenAI has released GPT-5. The new model demonstrates significant improvements in chain-of-thought reasoning, scoring 95% on graduate-level math benchmarks.',
        'John Timmer', NOW() - INTERVAL '1 hour',
        'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6abcd', 420, 2),

    -- Science
    (3, 'NASA Confirms Water Ice Deposits on Mars Surface',
        'https://nasa.gov/2026/03/29/mars-water-ice',
        'New data from the Mars Reconnaissance Orbiter confirms extensive water ice deposits just below the surface near the equator, opening possibilities for future missions.',
        'NASA PR', NOW() - INTERVAL '12 hours',
        'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6bcde', 280, 1),

    -- Business
    (6, 'Federal Reserve Holds Interest Rates Steady at 4.5%',
        'https://reuters.com/2026/03/30/fed-rates-hold',
        'The Federal Reserve voted unanimously to keep the benchmark interest rate at 4.5%, citing stable inflation and solid job growth in the first quarter.',
        'Reuters Staff', NOW() - INTERVAL '5 hours',
        'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6cdef', 190, 3),

    -- Sports — duplicate cluster
    (5, 'Lakers Win NBA Championship in Game 7 Thriller',
        'https://espn.com/nba/2026/03/30/lakers-championship',
        'The Los Angeles Lakers defeated the Boston Celtics 108-105 in a dramatic Game 7 to claim their 18th NBA championship. LeBron James scored 42 points.',
        'Adrian Wojnarowski', NOW() - INTERVAL '8 hours',
        'd4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6defg', 400, 2),
    (4, 'Los Angeles Lakers Clinch NBA Title With Game 7 Victory',
        'https://bbc.com/sport/2026/03/30/lakers-nba-title',
        'The LA Lakers have won the NBA championship after a thrilling Game 7 victory over the Celtics. LeBron James led the scoring with 42 points.',
        'BBC Sport', NOW() - INTERVAL '7 hours',
        'd4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6defg', 310, 2),

    -- Health
    (7, 'New Malaria Vaccine Shows 90% Effectiveness in Trials',
        'https://npr.org/2026/03/28/malaria-vaccine-trial',
        'A next-generation malaria vaccine developed by Oxford University showed 90% effectiveness in Phase 3 trials across six African countries.',
        'Rob Stein', NOW() - INTERVAL '48 hours',
        'e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6efgh', 520, 1),

    -- World
    (4, 'EU Passes Landmark AI Regulation Framework',
        'https://bbc.com/news/2026/03/29/eu-ai-regulation',
        'The European Parliament has approved comprehensive AI regulations requiring transparency, safety testing, and human oversight for high-risk AI systems.',
        'BBC News', NOW() - INTERVAL '24 hours',
        'f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6fghi', 450, 2),

    -- Technology
    (8, 'Show HN: I Built a Database That Runs on SQLite and Scales to 1M QPS',
        'https://news.ycombinator.com/item?id=99999',
        'A developer shares an open-source distributed database layer on top of SQLite, achieving one million queries per second on commodity hardware.',
        'hackernews_user', NOW() - INTERVAL '3 hours',
        'g1a2b3c4d5e6f7a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6ghij', 180, 1),

    -- More technology (unique stories)
    (1, 'Apple Unveils M5 Chip With 3nm Architecture',
        'https://techcrunch.com/2026/03/29/apple-m5-chip',
        'Apple announced the M5 processor built on TSMC 3nm process, delivering 40% better performance per watt compared to M4.',
        'Brian Heater', NOW() - INTERVAL '20 hours',
        'h2b3c4d5e6f7a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6hijk', 300, 1),

    -- Science
    (3, 'James Webb Telescope Discovers New Earth-Like Exoplanet',
        'https://nasa.gov/2026/03/28/jwst-exoplanet',
        'NASA JWST has identified a rocky planet in the habitable zone of a nearby star, with atmospheric signatures suggesting the presence of water vapor.',
        'NASA PR', NOW() - INTERVAL '36 hours',
        'i3c4d5e6f7a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6ijkl', 380, 1),

    -- Business
    (6, 'Global Chip Shortage Expected to Ease by Q3 2026',
        'https://reuters.com/2026/03/28/chip-shortage-easing',
        'Industry analysts predict the global semiconductor shortage will significantly ease by the third quarter of 2026 as new fabrication plants come online.',
        'Reuters Staff', NOW() - INTERVAL '40 hours',
        'j4d5e6f7a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6jklm', 250, 1),

    -- Entertainment (mapped via article_categories, feed is BBC)
    (4, 'Streaming Wars: Netflix Surpasses 300 Million Subscribers',
        'https://bbc.com/culture/2026/03/30/netflix-300m',
        'Netflix has reached 300 million global subscribers, driven by its live sports programming and a crackdown on password sharing.',
        'BBC Culture', NOW() - INTERVAL '6 hours',
        'k5e6f7a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6klmn', 200, 1);

-- Map articles to categories
INSERT INTO article_categories (article_id, category_id, relevance_score) VALUES
    (1,  1, 1.00),  -- GPT-5 (TechCrunch) → Technology
    (2,  1, 1.00),  -- GPT-5 (Ars) → Technology
    (3,  2, 1.00),  -- Mars ice → Science
    (4,  3, 1.00),  -- Fed rates → Business
    (5,  4, 1.00),  -- Lakers (ESPN) → Sports
    (6,  4, 1.00),  -- Lakers (BBC) → Sports
    (7,  6, 1.00),  -- Malaria vaccine → Health
    (8,  7, 0.80),  -- EU AI → Politics
    (8,  1, 0.60),  -- EU AI → Technology (also relevant)
    (9,  1, 1.00),  -- SQLite DB → Technology
    (10, 1, 1.00),  -- Apple M5 → Technology
    (11, 2, 1.00),  -- JWST exoplanet → Science
    (12, 3, 1.00),  -- Chip shortage → Business
    (12, 1, 0.50),  -- Chip shortage → Technology (also relevant)
    (13, 5, 1.00);  -- Netflix → Entertainment

-- Duplicate groups (articles reporting the same story)
INSERT INTO duplicate_groups (canonical_article_id) VALUES
    (1),   -- GPT-5 cluster → canonical = TechCrunch (published first)
    (5);   -- Lakers cluster → canonical = ESPN (more detail)

INSERT INTO duplicate_members (group_id, article_id, similarity_score) VALUES
    (1, 1, 1.00),  -- GPT-5 TechCrunch (canonical)
    (1, 2, 0.92),  -- GPT-5 Ars Technica (near-duplicate)
    (2, 5, 1.00),  -- Lakers ESPN (canonical)
    (2, 6, 0.88);  -- Lakers BBC (near-duplicate)

-- Users
INSERT INTO users (username, display_name) VALUES
    ('alice',   'Alice Johnson'),
    ('bob',     'Bob Smith'),
    ('carol',   'Carol Williams'),
    ('dave',    'Dave Brown'),
    ('eve',     'Eve Davis');

-- User interests (different profiles for personalisation demos)
-- Alice: tech enthusiast
INSERT INTO user_interests (user_id, category_id, weight) VALUES
    (1, 1, 1.00),  -- Technology
    (1, 2, 0.70),  -- Science
    (1, 3, 0.30);  -- Business

-- Bob: sports & entertainment fan
INSERT INTO user_interests (user_id, category_id, weight) VALUES
    (2, 4, 1.00),  -- Sports
    (2, 5, 0.80),  -- Entertainment
    (2, 6, 0.20);  -- Health

-- Carol: business & politics
INSERT INTO user_interests (user_id, category_id, weight) VALUES
    (3, 3, 1.00),  -- Business
    (3, 7, 0.90),  -- Politics
    (3, 8, 0.50);  -- World

-- Dave: science nerd
INSERT INTO user_interests (user_id, category_id, weight) VALUES
    (4, 2, 1.00),  -- Science
    (4, 1, 0.60),  -- Technology
    (4, 6, 0.40);  -- Health

-- Eve: reads everything
INSERT INTO user_interests (user_id, category_id, weight) VALUES
    (5, 1, 0.70),
    (5, 2, 0.70),
    (5, 3, 0.70),
    (5, 4, 0.70),
    (5, 5, 0.70),
    (5, 6, 0.70),
    (5, 7, 0.70),
    (5, 8, 0.70);

-- Sample interactions (past reading history)
INSERT INTO user_interactions (user_id, article_id, interaction_type, created_at) VALUES
    -- Alice reads tech articles
    (1, 1,  'click', NOW() - INTERVAL '1 hour'),
    (1, 1,  'read',  NOW() - INTERVAL '55 minutes'),
    (1, 9,  'click', NOW() - INTERVAL '2 hours'),
    (1, 10, 'click', NOW() - INTERVAL '18 hours'),
    (1, 10, 'bookmark', NOW() - INTERVAL '18 hours'),
    -- Bob reads sports
    (2, 5,  'click', NOW() - INTERVAL '7 hours'),
    (2, 5,  'read',  NOW() - INTERVAL '6 hours'),
    (2, 5,  'share', NOW() - INTERVAL '6 hours'),
    (2, 13, 'click', NOW() - INTERVAL '5 hours'),
    -- Carol reads business
    (3, 4,  'click', NOW() - INTERVAL '4 hours'),
    (3, 4,  'read',  NOW() - INTERVAL '3 hours'),
    (3, 8,  'click', NOW() - INTERVAL '22 hours'),
    (3, 12, 'click', NOW() - INTERVAL '38 hours'),
    -- Dave reads science
    (4, 3,  'click', NOW() - INTERVAL '10 hours'),
    (4, 3,  'read',  NOW() - INTERVAL '9 hours'),
    (4, 11, 'click', NOW() - INTERVAL '34 hours'),
    (4, 11, 'bookmark', NOW() - INTERVAL '34 hours');
