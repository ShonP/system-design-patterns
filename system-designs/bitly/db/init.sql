-- Bitly Lab Demo Database
-- URL shortener schema to demonstrate encoding, caching, and analytics

-- ============================================================
-- Core table: maps short codes to original URLs
-- ============================================================
CREATE TABLE urls (
    id BIGSERIAL PRIMARY KEY,
    short_code VARCHAR(10) UNIQUE NOT NULL,
    long_url TEXT NOT NULL,
    custom_alias VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    creator_ip VARCHAR(45)
);

-- ============================================================
-- Analytics table: one row per click
-- ============================================================
CREATE TABLE clicks (
    id BIGSERIAL PRIMARY KEY,
    short_code VARCHAR(10) NOT NULL REFERENCES urls(short_code),
    clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    referrer TEXT,
    user_agent TEXT,
    ip_address VARCHAR(45),
    country VARCHAR(2)
);

-- ============================================================
-- Indexes for fast lookups
-- ============================================================

-- The most critical index: redirect lookups by short_code
CREATE INDEX idx_urls_short_code ON urls(short_code);

-- Analytics queries often filter by short_code + time range
CREATE INDEX idx_clicks_short_code ON clicks(short_code);
CREATE INDEX idx_clicks_time ON clicks(clicked_at);

-- ============================================================
-- Seed data: sample shortened URLs
-- ============================================================
INSERT INTO urls (short_code, long_url, creator_ip) VALUES
    ('abc123', 'https://www.example.com/very/long/path/to/a/page?with=many&query=params', '127.0.0.1'),
    ('gH7kL9', 'https://docs.python.org/3/library/hashlib.html', '127.0.0.1'),
    ('Xy3mN8', 'https://redis.io/docs/latest/commands/get/', '127.0.0.1'),
    ('qW5rT2', 'https://www.postgresql.org/docs/current/indexes.html', '127.0.0.1'),
    ('pL4jF6', 'https://en.wikipedia.org/wiki/Base62', '127.0.0.1'),
    ('dK8vB1', 'https://fastapi.tiangolo.com/tutorial/', '127.0.0.1'),
    ('zN9cX3', 'https://github.com/features/actions', '127.0.0.1'),
    ('mR2hY7', 'https://www.cloudflare.com/learning/cdn/what-is-a-cdn/', '127.0.0.1'),
    ('tJ6wA4', 'https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/302', '127.0.0.1'),
    ('vF1sE5', 'https://www.hellointerview.com/learn/system-design/problem-breakdowns/bitly', '127.0.0.1');

-- Seed clicks so analytics notebook has data to work with
INSERT INTO clicks (short_code, clicked_at, referrer, user_agent, ip_address, country)
SELECT
    (ARRAY['abc123','gH7kL9','Xy3mN8','qW5rT2','pL4jF6','dK8vB1','zN9cX3','mR2hY7','tJ6wA4','vF1sE5'])[
        floor(random() * 10 + 1)::int
    ],
    NOW() - (random() * interval '30 days'),
    (ARRAY[
        'https://twitter.com', 'https://facebook.com', 'https://linkedin.com',
        'https://reddit.com', 'https://news.ycombinator.com', NULL
    ])[floor(random() * 6 + 1)::int],
    (ARRAY[
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)',
        'Mozilla/5.0 (Linux; Android 14)'
    ])[floor(random() * 4 + 1)::int],
    '192.168.1.' || floor(random() * 254 + 1)::int,
    (ARRAY['US','GB','DE','FR','JP','BR','IN','CA','AU','KR'])[
        floor(random() * 10 + 1)::int
    ]
FROM generate_series(1, 2000) AS i;
