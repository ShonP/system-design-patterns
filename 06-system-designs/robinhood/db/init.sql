-- ============================================================
-- Robinhood Lab — Database Schema
-- A simplified brokerage: users, symbols, orders, trades, positions
-- ============================================================

-- Users of the brokerage
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    balance_cents BIGINT NOT NULL DEFAULT 10000000,  -- $100,000 starting balance (in cents)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tradeable stock symbols
CREATE TABLE symbols (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(10) UNIQUE NOT NULL,        -- e.g. AAPL, META
    company_name VARCHAR(255) NOT NULL,
    last_price_cents BIGINT NOT NULL DEFAULT 0, -- latest known price in cents
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders placed by users (the heart of the brokerage)
-- Status workflow: pending → submitted → filled / cancelled / failed
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    symbol_id INTEGER NOT NULL REFERENCES symbols(id),
    side VARCHAR(4) NOT NULL CHECK (side IN ('buy', 'sell')),
    order_type VARCHAR(6) NOT NULL CHECK (order_type IN ('market', 'limit')),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    limit_price_cents BIGINT,                   -- NULL for market orders
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'submitted', 'filled', 'partially_filled',
                          'cancelled', 'pending_cancel', 'failed')),
    filled_quantity INTEGER NOT NULL DEFAULT 0,
    filled_avg_price_cents BIGINT,
    external_order_id VARCHAR(100),             -- ID returned by the exchange
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Executed trades (one order can produce multiple trades / partial fills)
CREATE TABLE trades (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    symbol_id INTEGER NOT NULL REFERENCES symbols(id),
    price_cents BIGINT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Portfolio positions — one row per (user, symbol)
CREATE TABLE positions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    symbol_id INTEGER NOT NULL REFERENCES symbols(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    avg_cost_cents BIGINT NOT NULL DEFAULT 0,   -- average purchase price in cents
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, symbol_id)
);

-- Historical price snapshots (for charts / analytics)
CREATE TABLE price_history (
    id SERIAL PRIMARY KEY,
    symbol_id INTEGER NOT NULL REFERENCES symbols(id),
    price_cents BIGINT NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_symbol ON orders(symbol_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_trades_order ON trades(order_id);
CREATE INDEX idx_trades_symbol ON trades(symbol_id);
CREATE INDEX idx_positions_user ON positions(user_id);
CREATE INDEX idx_price_history_symbol ON price_history(symbol_id, recorded_at);

-- ============================================================
-- Seed data
-- ============================================================

-- 10 demo users
INSERT INTO users (username, email, balance_cents) VALUES
    ('alice',   'alice@example.com',   10000000),
    ('bob',     'bob@example.com',     10000000),
    ('charlie', 'charlie@example.com', 10000000),
    ('diana',   'diana@example.com',   10000000),
    ('eve',     'eve@example.com',     10000000),
    ('frank',   'frank@example.com',   10000000),
    ('grace',   'grace@example.com',   10000000),
    ('heidi',   'heidi@example.com',   10000000),
    ('ivan',    'ivan@example.com',    10000000),
    ('judy',    'judy@example.com',    10000000);

-- 10 popular stock symbols with realistic starting prices (in cents)
INSERT INTO symbols (ticker, company_name, last_price_cents) VALUES
    ('AAPL',  'Apple Inc.',              19150),
    ('GOOGL', 'Alphabet Inc.',           17825),
    ('META',  'Meta Platforms Inc.',      52210),
    ('AMZN',  'Amazon.com Inc.',         18540),
    ('MSFT',  'Microsoft Corporation',   42080),
    ('TSLA',  'Tesla Inc.',              24530),
    ('NVDA',  'NVIDIA Corporation',      88100),
    ('NFLX',  'Netflix Inc.',            62840),
    ('JPM',   'JPMorgan Chase & Co.',    19670),
    ('V',     'Visa Inc.',               28140);

-- Give some users starting positions
INSERT INTO positions (user_id, symbol_id, quantity, avg_cost_cents) VALUES
    (1, 1, 50, 18000),   -- alice owns 50 AAPL @ $180.00
    (1, 3, 20, 50000),   -- alice owns 20 META @ $500.00
    (2, 7, 10, 85000),   -- bob owns 10 NVDA @ $850.00
    (3, 4, 30, 17500),   -- charlie owns 30 AMZN @ $175.00
    (4, 6, 100, 22000);  -- diana owns 100 TSLA @ $220.00

-- A few historical orders (already filled) so notebooks have data to query
INSERT INTO orders (user_id, symbol_id, side, order_type, quantity, limit_price_cents,
                    status, filled_quantity, filled_avg_price_cents, created_at) VALUES
    (1, 1, 'buy',  'market', 50,  NULL,  'filled', 50, 18000, NOW() - INTERVAL '30 days'),
    (1, 3, 'buy',  'limit',  20,  50000, 'filled', 20, 50000, NOW() - INTERVAL '20 days'),
    (2, 7, 'buy',  'market', 10,  NULL,  'filled', 10, 85000, NOW() - INTERVAL '15 days'),
    (3, 4, 'buy',  'market', 30,  NULL,  'filled', 30, 17500, NOW() - INTERVAL '10 days'),
    (4, 6, 'buy',  'limit', 100,  22000, 'filled',100, 22000, NOW() - INTERVAL '5 days');

-- ...and the trade rows that back them. An order marked 'filled' with no
-- matching row in `trades` is a hole in the ledger: the positions above could
-- never be rebuilt or audited from history. Every fill gets an execution.
INSERT INTO trades (order_id, symbol_id, price_cents, quantity, executed_at) VALUES
    (1, 1, 18000,  50, NOW() - INTERVAL '30 days'),
    (2, 3, 50000,  20, NOW() - INTERVAL '20 days'),
    (3, 7, 85000,  10, NOW() - INTERVAL '15 days'),
    (4, 4, 17500,  30, NOW() - INTERVAL '10 days'),
    (5, 6, 22000, 100, NOW() - INTERVAL '5 days');

-- Seed some price history (last 24 hours, every 30 min) for charting demos
INSERT INTO price_history (symbol_id, price_cents, recorded_at)
SELECT
    s.id,
    s.last_price_cents + (random() * 400 - 200)::int,  -- ±$2.00 jitter
    NOW() - (i || ' minutes')::interval
FROM symbols s,
     generate_series(0, 1440, 30) AS i;   -- 48 data points per symbol
