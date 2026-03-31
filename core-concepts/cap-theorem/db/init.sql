-- CAP Theorem Lab Demo Database
-- Ticket booking + social media schema to demonstrate consistency vs availability trade-offs

-- ============================================================
-- Replication user (used by the replica to connect to primary)
-- ============================================================
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator';
SELECT pg_create_physical_replication_slot('replica_slot_1');

-- ============================================================
-- Tables
-- ============================================================

-- Events (concerts, flights, etc.)
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    venue VARCHAR(255) NOT NULL,
    event_date TIMESTAMP NOT NULL,
    total_seats INTEGER NOT NULL,
    available_seats INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seat reservations — requires STRONG CONSISTENCY (no double-booking!)
CREATE TABLE seat_reservations (
    id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(id),
    seat_number VARCHAR(10) NOT NULL,
    user_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'confirmed',
    reserved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, seat_number)
);

-- User profiles — can tolerate EVENTUAL CONSISTENCY
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    bio TEXT DEFAULT '',
    profile_views INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Social posts — can tolerate EVENTUAL CONSISTENCY
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user_profiles(id),
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bank accounts — requires STRONG CONSISTENCY
CREATE TABLE bank_accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction log
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    from_account INTEGER REFERENCES bank_accounts(id),
    to_account INTEGER REFERENCES bank_accounts(id),
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Seed data
-- ============================================================

-- Events
INSERT INTO events (name, venue, event_date, total_seats, available_seats) VALUES
    ('Taylor Swift – Eras Tour', 'Madison Square Garden', '2026-07-15 20:00:00', 20, 20),
    ('NBA Finals Game 7', 'Chase Center', '2026-06-20 19:00:00', 15, 15),
    ('Broadway: Hamilton', 'Richard Rodgers Theatre', '2026-08-01 19:30:00', 10, 10),
    ('Tech Conference 2026', 'Moscone Center', '2026-09-10 09:00:00', 50, 50),
    ('Comedy Night Special', 'The Comedy Store', '2026-05-20 21:00:00', 8, 8);

-- Users
INSERT INTO user_profiles (username, display_name, bio, profile_views) VALUES
    ('alice', 'Alice Johnson', 'Software engineer who loves distributed systems', 1500),
    ('bob', 'Bob Smith', 'Full-stack developer and coffee enthusiast', 3200),
    ('carol', 'Carol Williams', 'Data scientist exploring the world of ML', 800),
    ('dave', 'Dave Brown', 'DevOps engineer automating everything', 2100),
    ('eve', 'Eve Davis', 'Security researcher and CTF player', 4500);

-- Generate more users
INSERT INTO user_profiles (username, display_name, bio, profile_views)
SELECT
    'user' || i,
    'User ' || i,
    'Sample user #' || i || ' for demo purposes',
    floor(random() * 5000)::int
FROM generate_series(6, 50) AS i;

-- Posts
INSERT INTO posts (user_id, content, like_count, created_at)
SELECT
    (floor(random() * 50) + 1)::int,
    CASE (i % 5)
        WHEN 0 THEN 'Just deployed a new microservice! 🚀'
        WHEN 1 THEN 'CAP theorem is fascinating once you understand it'
        WHEN 2 THEN 'Hot take: eventual consistency is fine for 90% of use cases'
        WHEN 3 THEN 'Working on a distributed database today'
        WHEN 4 THEN 'Redis is amazing for caching but also great as a primary store'
    END,
    floor(random() * 200)::int,
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 200) AS i;

-- Bank accounts
INSERT INTO bank_accounts (user_id, account_name, balance) VALUES
    (1, 'Alice Checking', 5000.00),
    (1, 'Alice Savings', 15000.00),
    (2, 'Bob Checking', 3000.00),
    (2, 'Bob Savings', 8000.00),
    (3, 'Carol Checking', 7500.00);

-- Indexes
CREATE INDEX idx_reservations_event ON seat_reservations(event_id);
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_transactions_from ON transactions(from_account);
CREATE INDEX idx_transactions_to ON transactions(to_account);
CREATE INDEX idx_bank_accounts_user ON bank_accounts(user_id);
