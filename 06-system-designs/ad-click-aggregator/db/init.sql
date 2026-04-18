-- Ad Click Aggregator Lab — Database Schema
-- This file runs automatically when the Postgres container starts for the
-- first time. It creates the tables we need and seeds them with sample data.

-- ============================================================
-- 1. Ads — the advertisements whose clicks we are tracking
-- ============================================================
CREATE TABLE ads (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,
    advertiser  VARCHAR(100) NOT NULL,
    target_url  VARCHAR(500) NOT NULL,
    budget      DECIMAL(10,2) DEFAULT 0,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. Raw click events — every single click before aggregation
-- ============================================================
CREATE TABLE click_events (
    id              SERIAL PRIMARY KEY,
    ad_id           INTEGER NOT NULL REFERENCES ads(id),
    impression_id   VARCHAR(64) NOT NULL,    -- unique per ad-show
    user_id         VARCHAR(64),             -- nullable for anonymous users
    ip_address      VARCHAR(45),
    user_agent      TEXT,
    event_time      TIMESTAMP NOT NULL,      -- when the click happened (event time)
    processed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. Pre-aggregated click metrics — one row per ad per minute
-- ============================================================
CREATE TABLE click_aggregates (
    ad_id           INTEGER NOT NULL REFERENCES ads(id),
    window_start    TIMESTAMP NOT NULL,      -- start of the 1-minute window
    click_count     INTEGER DEFAULT 0,
    unique_users    INTEGER DEFAULT 0,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ad_id, window_start)
);

-- ============================================================
-- 4. Indexes for the queries we will run
-- ============================================================
CREATE INDEX idx_click_events_ad_time   ON click_events(ad_id, event_time);
CREATE INDEX idx_click_events_impression ON click_events(impression_id);
CREATE INDEX idx_aggregates_time        ON click_aggregates(window_start);

-- ============================================================
-- 5. Seed data — sample ads
-- ============================================================
INSERT INTO ads (title, advertiser, target_url, budget) VALUES
    ('Nike Air Max — Just Do It',     'Nike',       'https://nike.com/air-max',       50000.00),
    ('MacBook Pro M4 — Power Meets Pro', 'Apple',   'https://apple.com/macbook-pro',  80000.00),
    ('AWS Free Tier — Build on AWS',  'Amazon',      'https://aws.amazon.com/free',    30000.00),
    ('Spotify Premium — 3 Months Free','Spotify',    'https://spotify.com/premium',    20000.00),
    ('Tesla Model 3 — Order Now',     'Tesla',       'https://tesla.com/model3',       60000.00),
    ('Duolingo Plus — Learn for Free','Duolingo',    'https://duolingo.com/plus',      15000.00),
    ('GitHub Copilot — Your AI Pair Programmer','GitHub','https://github.com/features/copilot',25000.00),
    ('Coursera — Online Degrees',     'Coursera',    'https://coursera.org',           18000.00),
    ('Notion — All-in-one Workspace', 'Notion',      'https://notion.so',              12000.00),
    ('Figma — Design Together',       'Figma',       'https://figma.com',              22000.00);
