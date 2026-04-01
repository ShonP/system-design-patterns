-- Online Auction Lab Database
-- Schema for auctions, items, users, and bids

-- ============================================================
-- Tables
-- ============================================================

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Items table (normalized separately from auctions so items can be relisted)
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    seller_id INTEGER REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(512),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Auctions table
-- max_bid_amount is denormalized here for fast reads (acts as a "cache" in the DB)
CREATE TABLE auctions (
    id SERIAL PRIMARY KEY,
    item_id INTEGER REFERENCES items(id),
    seller_id INTEGER REFERENCES users(id),
    starting_price DECIMAL(12,2) NOT NULL,
    max_bid_amount DECIMAL(12,2) DEFAULT 0,
    max_bid_user_id INTEGER REFERENCES users(id),
    start_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'ended', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bids table (full audit trail — never delete bid history)
CREATE TABLE bids (
    id SERIAL PRIMARY KEY,
    auction_id INTEGER REFERENCES auctions(id),
    user_id INTEGER REFERENCES users(id),
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'accepted' CHECK (status IN ('accepted', 'rejected')),
    bid_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_auctions_status ON auctions(status);
CREATE INDEX idx_auctions_end_date ON auctions(end_date);
CREATE INDEX idx_auctions_item ON auctions(item_id);
CREATE INDEX idx_bids_auction ON bids(auction_id);
CREATE INDEX idx_bids_user ON bids(user_id);
CREATE INDEX idx_bids_auction_amount ON bids(auction_id, amount DESC);
CREATE INDEX idx_items_seller ON items(seller_id);

-- ============================================================
-- Seed data
-- ============================================================

-- 50 sample users
INSERT INTO users (username, email)
SELECT
    'user' || i,
    'user' || i || '@example.com'
FROM generate_series(1, 50) AS i;

-- 30 sample items across different categories
INSERT INTO items (seller_id, name, description) VALUES
    (1,  'Vintage Gibson Les Paul 1959',        'Original sunburst finish, all-original electronics. A true collectors dream.'),
    (2,  'Signed First Edition — The Great Gatsby', 'First printing with original dust jacket. Signed by Fitzgerald.'),
    (3,  'Rolex Submariner 1968',               'Ref 5513, meters-first dial, original bracelet.'),
    (4,  'Original Star Wars Movie Poster 1977', 'Style A one-sheet. Linen-backed, excellent condition.'),
    (5,  'MacBook Pro M3 Max (sealed)',          'Brand new, sealed in box. 96 GB RAM, 2 TB SSD.'),
    (6,  'Antique Persian Rug 1920s',            '12x9 ft, hand-knotted silk and wool blend.'),
    (7,  'Rare Pokemon Card — Charizard 1st Ed', 'PSA 9 Mint. Base set, shadowless, 1st edition.'),
    (8,  'Canon EOS R5 + RF 28-70mm f/2',       'Low shutter count, includes battery grip.'),
    (9,  'Signed Michael Jordan Jersey',         'Game-worn Chicago Bulls jersey, 1996 season. COA included.'),
    (10, 'Vintage Leica M3 Camera',              'Double stroke, 1955 model. Recently CLA serviced.'),
    (11, 'Tesla Model S Plaid (2024)',            '1,200 miles, white exterior, full self-driving package.'),
    (12, 'Handmade Italian Leather Bag',         'Full-grain leather, handstitched in Florence.'),
    (13, 'Nintendo 64 Console — Complete Set',    'All original cables, 2 controllers, 12 games including Goldeneye.'),
    (14, 'Bose QuietComfort Ultra Headphones',   'Sealed, brand new. Noise cancelling, spatial audio.'),
    (15, 'Antique Oak Writing Desk 1890s',       'Roll-top desk with original key. Fully restored.'),
    (16, 'Dyson V15 Detect Vacuum',              'Like new, used twice. Includes all attachments.'),
    (17, 'LEGO Star Wars UCS Millennium Falcon', 'Set 75192. Sealed, retired. 7,541 pieces.'),
    (18, 'KitchenAid Pro Stand Mixer',           'Empire Red, 600 series. Bowl-lift design.'),
    (19, 'Fender Stratocaster 1963',             'Olympic White, rosewood fretboard. Pre-CBS.'),
    (20, 'Original Banksy Print — Girl with Balloon', 'Numbered and signed. Certificate of authenticity.');

-- 20 auctions (some active, some ended)
INSERT INTO auctions (item_id, seller_id, starting_price, max_bid_amount, max_bid_user_id, start_date, end_date, status) VALUES
    -- Active auctions (end in the future)
    (1,  1,  5000.00,  8500.00,  12, NOW() - interval '2 days',  NOW() + interval '5 days',  'active'),
    (2,  2,  1000.00,  3200.00,  15, NOW() - interval '1 day',   NOW() + interval '6 days',  'active'),
    (3,  3,  8000.00, 12000.00,  22, NOW() - interval '3 days',  NOW() + interval '4 days',  'active'),
    (4,  4,   500.00,  1800.00,  30, NOW() - interval '1 day',   NOW() + interval '3 days',  'active'),
    (5,  5,  3000.00,  3500.00,   8, NOW() - interval '4 hours', NOW() + interval '7 days',  'active'),
    (6,  6,  2000.00,  2000.00,  NULL, NOW(),                     NOW() + interval '10 days', 'active'),
    (7,  7, 15000.00, 22000.00,  45, NOW() - interval '5 days',  NOW() + interval '2 days',  'active'),
    (8,  8,  4000.00,  5100.00,  18, NOW() - interval '2 days',  NOW() + interval '5 days',  'active'),
    (9,  9, 10000.00, 15000.00,  33, NOW() - interval '6 days',  NOW() + interval '1 day',   'active'),
    (10, 10, 3000.00,  4200.00,  27, NOW() - interval '3 days',  NOW() + interval '4 days',  'active'),
    -- Ended auctions
    (11, 11, 80000.00, 95000.00, 40, NOW() - interval '14 days', NOW() - interval '1 day',   'ended'),
    (12, 12,   200.00,   450.00, 19, NOW() - interval '10 days', NOW() - interval '3 days',  'ended'),
    (13, 13,   150.00,   320.00, 25, NOW() - interval '7 days',  NOW() - interval '2 hours', 'ended'),
    (14, 14,   250.00,   250.00, NULL, NOW() - interval '7 days',NOW() - interval '1 day',   'ended'),
    (15, 15,  1500.00,  2800.00, 11, NOW() - interval '12 days', NOW() - interval '5 days',  'ended'),
    -- More active auctions for concurrency demos
    (16, 16,   300.00,   300.00, NULL, NOW(),                     NOW() + interval '3 days',  'active'),
    (17, 17,  5000.00,  7200.00,  5, NOW() - interval '2 days',  NOW() + interval '5 days',  'active'),
    (18, 18,   400.00,   550.00, 38, NOW() - interval '1 day',   NOW() + interval '6 days',  'active'),
    (19, 19,  8000.00, 11000.00, 42, NOW() - interval '4 days',  NOW() + interval '3 days',  'active'),
    (20, 20,  2000.00,  3600.00, 14, NOW() - interval '3 days',  NOW() + interval '4 days',  'active');

-- Sample bids for existing auctions
INSERT INTO bids (auction_id, user_id, amount, status, bid_time)
SELECT
    a.id,
    (floor(random() * 50) + 1)::int,
    a.starting_price + (row_num * 100) + (random() * 200)::decimal(12,2),
    'accepted',
    a.start_date + (row_num * interval '2 hours')
FROM auctions a
CROSS JOIN generate_series(1, 8) AS row_num
WHERE a.max_bid_amount > a.starting_price;

-- Add some rejected bids for realism
INSERT INTO bids (auction_id, user_id, amount, status, bid_time)
SELECT
    a.id,
    (floor(random() * 50) + 1)::int,
    a.starting_price + (random() * 50)::decimal(12,2),
    'rejected',
    a.start_date + interval '1 hour' + (row_num * interval '30 minutes')
FROM auctions a
CROSS JOIN generate_series(1, 3) AS row_num
WHERE a.max_bid_amount > a.starting_price;
