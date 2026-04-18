-- =============================================================================
-- BCDR Lab — Sample Order Data
-- =============================================================================
-- This simulates a critical e-commerce order processing system.
-- In real enterprises (banks, healthcare, retail), losing even ONE transaction
-- can mean regulatory fines, lost revenue, or broken customer trust.
-- =============================================================================

-- Customers table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    tier VARCHAR(20) DEFAULT 'standard',  -- standard, premium, enterprise
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table — the most critical data in this system
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(30) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Individual items within each order
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL
);

-- Payment records — financial data, extremely sensitive
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    payment_method VARCHAR(50) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(30) DEFAULT 'pending',
    transaction_id VARCHAR(100) UNIQUE,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log — tracks every change for compliance
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL,  -- INSERT, UPDATE, DELETE
    old_data JSONB,
    new_data JSONB,
    changed_by VARCHAR(100) DEFAULT 'system',
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Seed data
-- =============================================================================

-- 50 customers across different tiers
INSERT INTO customers (name, email, tier)
SELECT
    'Customer ' || i,
    'customer' || i || '@example.com',
    (ARRAY['standard', 'standard', 'premium', 'premium', 'enterprise'])[((i - 1) % 5) + 1]
FROM generate_series(1, 50) AS i;

-- 500 orders spread over the last 30 days
INSERT INTO orders (customer_id, order_number, total_amount, status, created_at)
SELECT
    ((i - 1) % 50) + 1,
    'ORD-' || LPAD(i::text, 6, '0'),
    (random() * 999 + 10.00)::decimal(12,2),
    (ARRAY['pending', 'confirmed', 'shipped', 'delivered', 'delivered'])[((i - 1) % 5) + 1],
    NOW() - (random() * interval '30 days')
FROM generate_series(1, 500) AS i;

-- 1500 order items (roughly 3 items per order)
INSERT INTO order_items (order_id, product_name, quantity, unit_price, subtotal)
SELECT
    ((i - 1) % 500) + 1,
    (ARRAY[
        'Wireless Mouse', 'USB-C Cable', 'Laptop Stand', 'Webcam HD',
        'Keyboard', 'Monitor Arm', 'Desk Lamp', 'Headphones',
        'Power Bank', 'Phone Case'
    ])[((i - 1) % 10) + 1],
    floor(random() * 3 + 1)::int,
    (random() * 100 + 5.00)::decimal(10,2),
    (random() * 300 + 5.00)::decimal(12,2)
FROM generate_series(1, 1500) AS i;

-- 500 payments (one per order)
INSERT INTO payments (order_id, payment_method, amount, status, transaction_id, processed_at)
SELECT
    i,
    (ARRAY['credit_card', 'debit_card', 'paypal', 'bank_transfer'])[((i - 1) % 4) + 1],
    (SELECT total_amount FROM orders WHERE id = i),
    CASE WHEN i % 20 = 0 THEN 'failed' ELSE 'completed' END,
    'TXN-' || md5(i::text),
    (SELECT created_at FROM orders WHERE id = i) + interval '5 minutes'
FROM generate_series(1, 500) AS i;

-- Indexes for performance
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_audit_table ON audit_log(table_name, record_id);
