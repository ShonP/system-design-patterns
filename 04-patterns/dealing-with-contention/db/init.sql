-- Concert tickets table for demonstrating contention
CREATE TABLE IF NOT EXISTS concerts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    venue VARCHAR(255) NOT NULL,
    available_seats INTEGER NOT NULL DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tickets purchased
CREATE TABLE IF NOT EXISTS tickets (
    id SERIAL PRIMARY KEY,
    concert_id INTEGER REFERENCES concerts(id),
    user_id VARCHAR(255) NOT NULL,
    seat_number VARCHAR(50),
    purchase_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bank accounts for demonstrating transfers
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction log for demonstrating sagas
CREATE TABLE IF NOT EXISTS transaction_log (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(255) NOT NULL,
    step_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Auction items for demonstrating optimistic concurrency
CREATE TABLE IF NOT EXISTS auction_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    current_bid DECIMAL(15, 2) NOT NULL DEFAULT 0,
    highest_bidder VARCHAR(255),
    bid_count INTEGER NOT NULL DEFAULT 0,
    ends_at TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bids history
CREATE TABLE IF NOT EXISTS bids (
    id SERIAL PRIMARY KEY,
    auction_item_id INTEGER REFERENCES auction_items(id),
    user_id VARCHAR(255) NOT NULL,
    bid_amount DECIMAL(15, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'placed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seat reservations for demonstrating distributed locks pattern
CREATE TABLE IF NOT EXISTS seat_reservations (
    id SERIAL PRIMARY KEY,
    concert_id INTEGER REFERENCES concerts(id),
    seat_number VARCHAR(50) NOT NULL,
    user_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'available',
    reserved_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(concert_id, seat_number)
);

-- Insert sample data
INSERT INTO concerts (name, venue, available_seats, price) VALUES
    ('The Weeknd - After Hours Tour', 'Madison Square Garden', 5, 150.00),
    ('Taylor Swift - Eras Tour', 'SoFi Stadium', 3, 500.00),
    ('Drake - It''s All A Blur Tour', 'Barclays Center', 10, 200.00);

INSERT INTO accounts (user_id, balance) VALUES
    ('alice', 1000.00),
    ('bob', 500.00),
    ('charlie', 2000.00);

INSERT INTO auction_items (name, description, current_bid, ends_at) VALUES
    ('Rare Pokemon Card', 'First edition Charizard', 100.00, NOW() + INTERVAL '1 hour'),
    ('Vintage Watch', 'Rolex Submariner 1960', 5000.00, NOW() + INTERVAL '2 hours'),
    ('Concert Tickets', 'Front row Taylor Swift', 1000.00, NOW() + INTERVAL '30 minutes');

-- Create individual seats for The Weeknd concert
INSERT INTO seat_reservations (concert_id, seat_number, status)
SELECT 1, 'A' || generate_series(1, 5), 'available';
