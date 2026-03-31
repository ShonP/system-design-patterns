-- Caching Lab Demo Database
-- E-commerce product catalog to demonstrate caching patterns

-- Categories table
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category_id INTEGER REFERENCES categories(id),
    brand VARCHAR(100),
    stock_quantity INTEGER DEFAULT 0,
    rating_avg DECIMAL(3,2) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reviews table
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    user_id INTEGER REFERENCES users(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table (for write-through/write-behind demos)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Price history (for cache invalidation demos)
CREATE TABLE price_history (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Seed data
-- ============================================================

-- Categories
INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Phones, laptops, gadgets and accessories'),
    ('Clothing', 'Shirts, pants, shoes and fashion items'),
    ('Home & Kitchen', 'Furniture, appliances and home goods'),
    ('Sports & Outdoors', 'Fitness equipment, camping and outdoor gear'),
    ('Books', 'Fiction, non-fiction and educational books');

-- Users (100 sample users)
INSERT INTO users (email, username)
SELECT
    'user' || i || '@example.com',
    'user' || i
FROM generate_series(1, 100) AS i;

-- Products (200 sample products across categories)
INSERT INTO products (name, description, price, category_id, brand, stock_quantity, rating_avg, rating_count, view_count, is_featured)
SELECT
    CASE (i % 5)
        WHEN 0 THEN 'Wireless Headphones Model ' || i
        WHEN 1 THEN 'Cotton T-Shirt Style ' || i
        WHEN 2 THEN 'Kitchen Blender Pro ' || i
        WHEN 3 THEN 'Yoga Mat Premium ' || i
        WHEN 4 THEN 'Programming Guide Vol ' || i
    END,
    'High quality product #' || i || '. Perfect for everyday use. Customers love this item.',
    (random() * 200 + 9.99)::decimal(10,2),
    (i % 5) + 1,
    'Brand ' || ((i % 15) + 1),
    floor(random() * 500 + 10)::int,
    (random() * 3 + 2)::decimal(3,2),
    floor(random() * 200 + 5)::int,
    floor(random() * 50000 + 100)::int,
    (i % 20 = 0)  -- every 20th product is featured
FROM generate_series(1, 200) AS i;

-- Reviews (1000 sample reviews)
INSERT INTO reviews (product_id, user_id, rating, title, content, created_at)
SELECT
    (floor(random() * 200) + 1)::int,
    (floor(random() * 100) + 1)::int,
    floor(random() * 5 + 1)::int,
    CASE floor(random() * 5)::int
        WHEN 0 THEN 'Great product!'
        WHEN 1 THEN 'Good value for money'
        WHEN 2 THEN 'Decent quality'
        WHEN 3 THEN 'Could be better'
        WHEN 4 THEN 'Excellent purchase'
    END,
    'Review #' || i || '. This product met my expectations. Would recommend.',
    NOW() - (random() * interval '90 days')
FROM generate_series(1, 1000) AS i;

-- Orders (500 sample orders)
INSERT INTO orders (user_id, product_id, quantity, total_price, status, created_at)
SELECT
    (floor(random() * 100) + 1)::int,
    (floor(random() * 200) + 1)::int,
    floor(random() * 3 + 1)::int,
    (random() * 500 + 10)::decimal(10,2),
    (ARRAY['pending', 'confirmed', 'shipped', 'delivered'])[floor(random() * 4 + 1)::int],
    NOW() - (random() * interval '60 days')
FROM generate_series(1, 500) AS i;

-- Add indexes that a real e-commerce DB would have
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_product ON orders(product_id);
