-- API Design Lab Demo Database
-- Event ticketing system to demonstrate REST API patterns

-- ============================================================
-- Schema
-- ============================================================

-- API versioning metadata
CREATE TABLE api_versions (
    version VARCHAR(10) PRIMARY KEY,
    released_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deprecated BOOLEAN DEFAULT FALSE,
    notes TEXT
);

-- Venues table
CREATE TABLE venues (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    capacity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events table
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    venue_id INTEGER REFERENCES venues(id),
    event_date TIMESTAMP NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    total_tickets INTEGER NOT NULL,
    tickets_sold INTEGER DEFAULT 0,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'customer',
    api_key VARCHAR(64) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bookings table
CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    event_id INTEGER REFERENCES events(id),
    quantity INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rate limit tracking (for demo purposes)
CREATE TABLE rate_limit_log (
    id SERIAL PRIMARY KEY,
    client_id VARCHAR(100) NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Seed data
-- ============================================================

-- API versions
INSERT INTO api_versions (version, released_at, deprecated, notes) VALUES
    ('v1', '2024-01-01', TRUE, 'Original API - events returned flat structure'),
    ('v2', '2024-06-01', FALSE, 'Added nested venue data, cursor pagination');

-- Venues
INSERT INTO venues (name, city, capacity) VALUES
    ('Madison Square Garden', 'New York', 20000),
    ('The O2 Arena', 'London', 20000),
    ('Staples Center', 'Los Angeles', 19000),
    ('Wembley Stadium', 'London', 90000),
    ('Red Rocks Amphitheatre', 'Denver', 9500),
    ('Sydney Opera House', 'Sydney', 5700),
    ('Tokyo Dome', 'Tokyo', 55000),
    ('Olympiastadion', 'Berlin', 74500);

-- Events (50 sample events)
INSERT INTO events (title, description, venue_id, event_date, price, total_tickets, tickets_sold, category)
SELECT
    CASE (i % 5)
        WHEN 0 THEN 'Rock Festival ' || (2024 + (i % 3)) || ' #' || i
        WHEN 1 THEN 'Jazz Night Vol. ' || i
        WHEN 2 THEN 'Comedy Show: Laughs Unlimited ' || i
        WHEN 3 THEN 'Tech Conference ' || (2024 + (i % 3))
        WHEN 4 THEN 'Classical Concert Series ' || i
    END,
    'An amazing event you do not want to miss! Event number ' || i || '.',
    (i % 8) + 1,
    NOW() + (i || ' days')::interval,
    (random() * 200 + 25)::decimal(10,2),
    floor(random() * 5000 + 500)::int,
    floor(random() * 2000)::int,
    (ARRAY['music', 'comedy', 'tech', 'sports', 'arts'])[floor(random() * 5 + 1)::int]
FROM generate_series(1, 50) AS i;

-- Users (30 sample users with different roles)
INSERT INTO users (email, username, role, api_key) VALUES
    ('admin@example.com', 'admin', 'admin', 'sk_admin_a1b2c3d4e5f6'),
    ('manager@venue.com', 'venue_mgr', 'venue_manager', 'sk_mgr_g7h8i9j0k1l2');

INSERT INTO users (email, username, role, api_key)
SELECT
    'user' || i || '@example.com',
    'user' || i,
    'customer',
    'sk_user_' || md5(random()::text)
FROM generate_series(1, 28) AS i;

-- Bookings (200 sample bookings)
INSERT INTO bookings (user_id, event_id, quantity, total_price, status, created_at)
SELECT
    floor(random() * 30 + 1)::int,
    floor(random() * 50 + 1)::int,
    floor(random() * 4 + 1)::int,
    (random() * 500 + 25)::decimal(10,2),
    (ARRAY['confirmed', 'confirmed', 'confirmed', 'cancelled', 'pending'])[floor(random() * 5 + 1)::int],
    NOW() - (random() * interval '90 days')
FROM generate_series(1, 200) AS i;

-- Indexes
CREATE INDEX idx_events_venue ON events(venue_id);
CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_event ON bookings(event_id);
CREATE INDEX idx_rate_limit_client ON rate_limit_log(client_id, requested_at);
