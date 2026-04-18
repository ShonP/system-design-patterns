-- ============================================================
-- Gopuff Lab: Local Delivery Service Database
-- Models micro-fulfillment centers, inventory, orders,
-- delivery zones, and demand/pricing data.
-- ============================================================

-- ============================================================
-- Distribution Centers (micro-fulfillment centers)
-- ============================================================
CREATE TABLE distribution_centers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(2) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    capacity_sqft INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Items (the product catalog — what customers see)
-- ============================================================
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL,
    weight_oz DECIMAL(8,2) DEFAULT 0,
    is_perishable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Inventory (physical stock at each DC)
-- A row here means "DC X has N units of item Y"
-- ============================================================
CREATE TABLE inventory (
    id SERIAL PRIMARY KEY,
    dc_id INTEGER NOT NULL REFERENCES distribution_centers(id),
    item_id INTEGER NOT NULL REFERENCES items(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    reorder_point INTEGER NOT NULL DEFAULT 10,
    max_capacity INTEGER NOT NULL DEFAULT 200,
    last_restocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (dc_id, item_id)
);

-- ============================================================
-- Orders & order items
-- ============================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    dc_id INTEGER NOT NULL REFERENCES distribution_centers(id),
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    delivery_address TEXT NOT NULL,
    delivery_lat DOUBLE PRECISION NOT NULL,
    delivery_lon DOUBLE PRECISION NOT NULL,
    estimated_delivery_minutes INTEGER,
    actual_delivery_minutes INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    item_id INTEGER NOT NULL REFERENCES items(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL
);

-- ============================================================
-- Delivery zones — maps DC coverage areas
-- ============================================================
CREATE TABLE delivery_zones (
    id SERIAL PRIMARY KEY,
    dc_id INTEGER NOT NULL REFERENCES distribution_centers(id),
    zone_name VARCHAR(100) NOT NULL,
    max_radius_miles DOUBLE PRECISION NOT NULL,
    avg_delivery_minutes INTEGER NOT NULL,
    surge_multiplier DECIMAL(4,2) DEFAULT 1.00
);

-- ============================================================
-- Demand log — historical demand per item per DC per hour
-- Used for forecasting and dynamic pricing
-- ============================================================
CREATE TABLE demand_log (
    id SERIAL PRIMARY KEY,
    dc_id INTEGER NOT NULL REFERENCES distribution_centers(id),
    item_id INTEGER NOT NULL REFERENCES items(id),
    hour_bucket TIMESTAMP NOT NULL,
    units_sold INTEGER NOT NULL DEFAULT 0,
    units_requested INTEGER NOT NULL DEFAULT 0,
    price_at_sale DECIMAL(10,2) NOT NULL
);

-- ============================================================
-- Dynamic prices — current price overrides
-- ============================================================
CREATE TABLE dynamic_prices (
    id SERIAL PRIMARY KEY,
    dc_id INTEGER NOT NULL REFERENCES distribution_centers(id),
    item_id INTEGER NOT NULL REFERENCES items(id),
    current_price DECIMAL(10,2) NOT NULL,
    surge_multiplier DECIMAL(4,2) DEFAULT 1.00,
    reason VARCHAR(100),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    UNIQUE (dc_id, item_id)
);

-- ============================================================
-- Indexes for performance
-- ============================================================
CREATE INDEX idx_inventory_dc ON inventory(dc_id);
CREATE INDEX idx_inventory_item ON inventory(item_id);
CREATE INDEX idx_inventory_dc_item ON inventory(dc_id, item_id);
CREATE INDEX idx_orders_dc ON orders(dc_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_demand_log_dc_item ON demand_log(dc_id, item_id);
CREATE INDEX idx_demand_log_hour ON demand_log(hour_bucket);
CREATE INDEX idx_delivery_zones_dc ON delivery_zones(dc_id);
CREATE INDEX idx_dynamic_prices_dc_item ON dynamic_prices(dc_id, item_id);

-- ============================================================
-- Seed data
-- ============================================================

-- 8 distribution centers across a metro area
INSERT INTO distribution_centers (name, city, state, zip_code, latitude, longitude, capacity_sqft) VALUES
    ('DC Downtown',      'Austin', 'TX', '78701', 30.2672,  -97.7431, 5000),
    ('DC East',          'Austin', 'TX', '78721', 30.2634,  -97.6934, 4000),
    ('DC South',         'Austin', 'TX', '78745', 30.2060,  -97.7954, 6000),
    ('DC North',         'Austin', 'TX', '78758', 30.3716,  -97.7064, 4500),
    ('DC West',          'Austin', 'TX', '78735', 30.2650,  -97.8500, 3500),
    ('DC University',    'Austin', 'TX', '78705', 30.2849,  -97.7341, 3000),
    ('DC Airport',       'Austin', 'TX', '78719', 30.1975,  -97.6664, 5500),
    ('DC Round Rock',    'Round Rock', 'TX', '78681', 30.5083, -97.6789, 4000);

-- Delivery zones for each DC
INSERT INTO delivery_zones (dc_id, zone_name, max_radius_miles, avg_delivery_minutes, surge_multiplier) VALUES
    (1, 'Downtown Core',    3.0, 15, 1.00),
    (1, 'Downtown Extended', 6.0, 25, 1.00),
    (2, 'East Core',        3.5, 18, 1.00),
    (2, 'East Extended',    7.0, 30, 1.00),
    (3, 'South Core',       4.0, 20, 1.00),
    (3, 'South Extended',   8.0, 35, 1.00),
    (4, 'North Core',       3.5, 18, 1.00),
    (4, 'North Extended',   7.0, 28, 1.00),
    (5, 'West Core',        3.0, 20, 1.00),
    (6, 'University Core',  2.5, 12, 1.00),
    (6, 'University Extended', 5.0, 22, 1.00),
    (7, 'Airport Core',     4.0, 22, 1.00),
    (8, 'Round Rock Core',  4.0, 20, 1.00),
    (8, 'Round Rock Extended', 8.0, 35, 1.00);

-- 30 convenience items across categories
INSERT INTO items (name, category, description, base_price, weight_oz, is_perishable) VALUES
    ('Coca-Cola 12-pack',     'Beverages',  'Classic Coke, 12 cans',             6.99, 144, FALSE),
    ('Red Bull 4-pack',       'Beverages',  'Energy drink, 4 cans',              8.49, 33.6, FALSE),
    ('Gatorade Blue',         'Beverages',  'Cool Blue, 28oz',                   2.29, 28, FALSE),
    ('Dasani Water 24pk',     'Beverages',  'Purified water, 24 bottles',        5.99, 405, FALSE),
    ('Whole Milk Gallon',     'Dairy',      'Whole milk, 1 gallon',              4.49, 128, TRUE),
    ('Greek Yogurt Vanilla',  'Dairy',      'Non-fat Greek yogurt, 32oz',        5.99, 32, TRUE),
    ('Eggs Large 12ct',       'Dairy',      'Grade A large eggs, dozen',         3.99, 24, TRUE),
    ('Cheddar Cheese Block',  'Dairy',      'Sharp cheddar, 8oz',               4.29, 8, TRUE),
    ('Doritos Nacho Cheese',  'Snacks',     'Party size, 14.5oz',               5.49, 14.5, FALSE),
    ('Lay''s Classic Chips',  'Snacks',     'Original, 10oz bag',               4.29, 10, FALSE),
    ('Oreo Cookies',          'Snacks',     'Original, 14.3oz',                  4.99, 14.3, FALSE),
    ('KIND Bars Variety',     'Snacks',     'Nut bars, 12-count',               14.99, 16.8, FALSE),
    ('Frozen Pizza Pepperoni','Frozen',     'DiGiorno Rising Crust',             7.49, 29.6, TRUE),
    ('Ice Cream Vanilla',     'Frozen',     'Ben & Jerry''s, pint',              5.99, 16, TRUE),
    ('Frozen Burritos 8pk',   'Frozen',     'Bean and cheese burritos',          6.49, 32, TRUE),
    ('Bananas 1 bunch',       'Produce',    'Fresh bananas, ~5 count',           1.29, 20, TRUE),
    ('Avocados 3-pack',       'Produce',    'Ripe Hass avocados',               4.49, 18, TRUE),
    ('Baby Spinach 5oz',      'Produce',    'Pre-washed organic spinach',        3.99, 5, TRUE),
    ('Tylenol Extra Strength','Health',     'Pain relief, 100 caplets',          9.99, 4, FALSE),
    ('Band-Aid Variety',      'Health',     'Adhesive bandages, 30ct',           4.49, 2, FALSE),
    ('Hand Sanitizer 8oz',    'Health',     'Purell advanced, 8oz',              3.99, 8, FALSE),
    ('Paper Towels 6-roll',   'Household',  'Bounty select-a-size',             12.99, 48, FALSE),
    ('Trash Bags 30ct',       'Household',  'Glad ForceFlex, 13gal',             9.99, 32, FALSE),
    ('AA Batteries 8-pack',   'Household',  'Duracell CopperTop',               8.49, 6.4, FALSE),
    ('Phone Charger USB-C',   'Electronics','Fast charge cable, 6ft',            12.99, 2, FALSE),
    ('Earbuds Wired',         'Electronics','Basic in-ear, 3.5mm',               7.99, 1, FALSE),
    ('Dog Treats Beggin',     'Pet',        'Bacon flavor, 6oz',                 4.99, 6, FALSE),
    ('Cat Food Wet 12pk',     'Pet',        'Fancy Feast variety, 12 cans',     11.99, 36, FALSE),
    ('Diapers Size 3 27ct',   'Baby',       'Pampers Swaddlers',                12.49, 32, FALSE),
    ('Baby Wipes 72ct',       'Baby',       'Huggies Natural Care',              3.49, 16, FALSE);

-- Spread inventory across DCs (each DC stocks most items with varying quantities)
INSERT INTO inventory (dc_id, item_id, quantity, reorder_point, max_capacity, last_restocked_at)
SELECT
    dc.id,
    it.id,
    -- Vary quantity by DC and item to make it interesting
    CASE
        WHEN it.category = 'Beverages' THEN floor(random() * 80 + 20)::int
        WHEN it.category = 'Snacks'    THEN floor(random() * 60 + 15)::int
        WHEN it.category = 'Dairy'     THEN floor(random() * 30 + 5)::int
        WHEN it.category = 'Produce'   THEN floor(random() * 20 + 3)::int
        ELSE floor(random() * 50 + 10)::int
    END,
    CASE WHEN it.is_perishable THEN 5 ELSE 10 END,
    CASE
        WHEN it.category = 'Beverages' THEN 150
        WHEN it.category = 'Snacks'    THEN 100
        ELSE 80
    END,
    NOW() - (random() * interval '7 days')
FROM distribution_centers dc
CROSS JOIN items it
-- Some DCs don't carry every item (80% chance of stocking)
WHERE random() < 0.80;

-- Generate 60 days of hourly demand history
INSERT INTO demand_log (dc_id, item_id, hour_bucket, units_sold, units_requested, price_at_sale)
SELECT
    dc.id,
    it.id,
    hour_ts,
    -- More demand during peak hours (11am-1pm, 5pm-9pm)
    CASE
        WHEN EXTRACT(HOUR FROM hour_ts) BETWEEN 11 AND 13 THEN floor(random() * 8 + 2)::int
        WHEN EXTRACT(HOUR FROM hour_ts) BETWEEN 17 AND 21 THEN floor(random() * 10 + 3)::int
        WHEN EXTRACT(HOUR FROM hour_ts) BETWEEN 0 AND 6   THEN floor(random() * 2)::int
        ELSE floor(random() * 4 + 1)::int
    END AS units_sold,
    CASE
        WHEN EXTRACT(HOUR FROM hour_ts) BETWEEN 11 AND 13 THEN floor(random() * 10 + 3)::int
        WHEN EXTRACT(HOUR FROM hour_ts) BETWEEN 17 AND 21 THEN floor(random() * 12 + 4)::int
        WHEN EXTRACT(HOUR FROM hour_ts) BETWEEN 0 AND 6   THEN floor(random() * 3)::int
        ELSE floor(random() * 5 + 1)::int
    END AS units_requested,
    it.base_price
FROM distribution_centers dc
CROSS JOIN items it
-- Generate one row per hour for the last 60 days, but sample ~20% to keep data manageable
CROSS JOIN generate_series(
    NOW() - interval '60 days',
    NOW(),
    interval '1 hour'
) AS hour_ts
WHERE random() < 0.02;  -- ~2% sampling → a few thousand rows

-- Generate 500 past orders spread over the last 30 days
INSERT INTO orders (customer_id, dc_id, status, total_price, delivery_address, delivery_lat, delivery_lon, estimated_delivery_minutes, actual_delivery_minutes, created_at, delivered_at)
SELECT
    floor(random() * 1000 + 1)::int,
    floor(random() * 8 + 1)::int,
    (ARRAY['delivered','delivered','delivered','delivered','in_transit','preparing','pending'])[floor(random() * 7 + 1)::int],
    (random() * 60 + 5)::decimal(10,2),
    floor(random() * 9999 + 100)::text || ' Main St, Austin, TX',
    30.2672 + (random() - 0.5) * 0.2,
    -97.7431 + (random() - 0.5) * 0.2,
    floor(random() * 30 + 10)::int,
    floor(random() * 40 + 8)::int,
    NOW() - (random() * interval '30 days'),
    NOW() - (random() * interval '29 days')
FROM generate_series(1, 500);

-- Generate order items for each order (1-4 items per order)
INSERT INTO order_items (order_id, item_id, quantity, unit_price)
SELECT
    o.id,
    floor(random() * 30 + 1)::int,
    floor(random() * 3 + 1)::int,
    (random() * 12 + 1.29)::decimal(10,2)
FROM orders o
CROSS JOIN generate_series(1, floor(random() * 3 + 1)::int);
