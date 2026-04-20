-- Security Review Lab Database
-- Intentionally includes patterns that demonstrate both vulnerable and secure approaches

-- Users table (for authentication demos)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Products table (for SQL injection demos)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100),
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Comments table (for XSS demos)
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log (for security monitoring demos)
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    resource VARCHAR(255),
    ip_address VARCHAR(45),
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions table (for session management demos)
CREATE TABLE sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- API keys table (for secrets management demos)
CREATE TABLE api_keys (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    key_hash VARCHAR(255) NOT NULL,
    label VARCHAR(100),
    permissions TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_revoked BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- Seed data
-- ============================================================

-- Users (passwords are bcrypt hashes of simple passwords for demo purposes)
-- Password for all users: "password123"
-- The hash below is a real bcrypt($2b$12) hash of "password123".
INSERT INTO users (username, email, password_hash, role) VALUES
    ('admin', 'admin@example.com', '$2b$12$xMdy/.AUFBirgZpJo72GSuRLEjo2w25UrCL2yf5U2CavEK6T.r1a2', 'admin'),
    ('alice', 'alice@example.com', '$2b$12$xMdy/.AUFBirgZpJo72GSuRLEjo2w25UrCL2yf5U2CavEK6T.r1a2', 'user'),
    ('bob', 'bob@example.com', '$2b$12$xMdy/.AUFBirgZpJo72GSuRLEjo2w25UrCL2yf5U2CavEK6T.r1a2', 'user'),
    ('charlie', 'charlie@example.com', '$2b$12$xMdy/.AUFBirgZpJo72GSuRLEjo2w25UrCL2yf5U2CavEK6T.r1a2', 'editor');

-- Products
INSERT INTO products (name, description, price, category, stock) VALUES
    ('Laptop Pro 15', 'High-performance laptop for developers', 1299.99, 'Electronics', 50),
    ('Mechanical Keyboard', 'Cherry MX switches, RGB backlight', 149.99, 'Electronics', 200),
    ('USB-C Hub', '7-in-1 USB-C adapter', 49.99, 'Accessories', 500),
    ('Monitor Stand', 'Ergonomic aluminum stand', 79.99, 'Accessories', 150),
    ('Webcam HD', '1080p webcam with microphone', 89.99, 'Electronics', 300),
    ('Desk Lamp', 'LED desk lamp with adjustable brightness', 39.99, 'Home Office', 400),
    ('Mouse Pad XL', 'Extended gaming mouse pad', 24.99, 'Accessories', 1000),
    ('Cable Organizer', 'Silicone cable management clips', 12.99, 'Accessories', 2000),
    ('Screen Protector', 'Anti-glare screen protector', 19.99, 'Accessories', 800),
    ('Laptop Bag', 'Water-resistant laptop backpack', 59.99, 'Accessories', 250);

-- Sample comments (some with XSS-like content for demos)
INSERT INTO comments (user_id, product_id, content) VALUES
    (2, 1, 'Great laptop, love the performance!'),
    (3, 1, 'Battery life could be better'),
    (2, 2, 'Best keyboard I have ever used'),
    (4, 3, 'Works perfectly with my MacBook'),
    (3, 5, 'Crystal clear video quality');

-- Indexes
CREATE INDEX idx_comments_product ON comments(product_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_sessions_user ON sessions(user_id);
CREATE INDEX idx_api_keys_user ON api_keys(user_id);
