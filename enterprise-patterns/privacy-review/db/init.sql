-- =============================================================================
-- Privacy Review Lab — Sample Database
-- =============================================================================
-- This database simulates a SaaS application that stores various types of
-- personal data. It's designed to demonstrate how PII (Personally Identifiable
-- Information) ends up scattered across tables and why privacy reviews matter.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- DATA CLASSIFICATION REFERENCE (Microsoft standard)
-- ─────────────────────────────────────────────────────────────────────────────
-- PUBLIC:       Product names, public docs, marketing content
-- INTERNAL:     Employee count, office locations, internal policies
-- CONFIDENTIAL: Customer names, email addresses, phone numbers
-- RESTRICTED:   SSNs, credit card numbers, health records, passwords
-- ─────────────────────────────────────────────────────────────────────────────

-- =============================================================================
-- USERS TABLE — Contains multiple PII fields
-- =============================================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    -- CONFIDENTIAL: identifies a person
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),

    -- RESTRICTED: highly sensitive identifiers
    ssn VARCHAR(11),                          -- Social Security Number
    date_of_birth DATE,

    -- CONFIDENTIAL: location data
    street_address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    country VARCHAR(50) DEFAULT 'US',

    -- INTERNAL: account metadata
    account_status VARCHAR(20) DEFAULT 'active',
    signup_source VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,

    -- Privacy tracking fields
    consent_marketing BOOLEAN DEFAULT FALSE,
    consent_analytics BOOLEAN DEFAULT TRUE,
    data_retention_category VARCHAR(20) DEFAULT 'standard'
);

-- =============================================================================
-- PAYMENT_METHODS — Restricted financial data
-- =============================================================================
CREATE TABLE payment_methods (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),

    -- RESTRICTED: payment card data (PCI DSS scope)
    card_number_encrypted VARCHAR(255),
    card_last_four VARCHAR(4),
    card_brand VARCHAR(20),
    expiry_month INTEGER,
    expiry_year INTEGER,
    billing_zip VARCHAR(10),

    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- ORDERS — Transaction history with embedded PII
-- =============================================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    order_number VARCHAR(20) UNIQUE NOT NULL,

    -- CONFIDENTIAL: shipping details duplicate user PII
    shipping_name VARCHAR(200),
    shipping_address VARCHAR(255),
    shipping_city VARCHAR(100),
    shipping_state VARCHAR(50),
    shipping_zip VARCHAR(10),
    shipping_country VARCHAR(50),

    -- PUBLIC: order metadata
    subtotal DECIMAL(10,2),
    tax DECIMAL(10,2),
    total DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP
);

-- =============================================================================
-- SUPPORT_TICKETS — May contain PII in free-text fields
-- =============================================================================
CREATE TABLE support_tickets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    subject VARCHAR(255),

    -- CONFIDENTIAL: free-text often contains PII accidentally
    description TEXT,

    -- Agents sometimes paste PII into internal notes
    internal_notes TEXT,

    priority VARCHAR(10) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- =============================================================================
-- ACTIVITY_LOG — Behavioral tracking data
-- =============================================================================
CREATE TABLE activity_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),

    -- CONFIDENTIAL: behavioral data tied to a user
    action VARCHAR(100),
    resource_type VARCHAR(50),
    resource_id INTEGER,
    ip_address VARCHAR(45),
    user_agent TEXT,

    -- Geolocation derived from IP
    geo_country VARCHAR(50),
    geo_city VARCHAR(100),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- DATA_CLASSIFICATION_REGISTRY — Tracks column classifications
-- =============================================================================
CREATE TABLE data_classification_registry (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    classification VARCHAR(20) NOT NULL
        CHECK (classification IN ('public', 'internal', 'confidential', 'restricted')),
    pii_type VARCHAR(50),
    notes TEXT,
    classified_by VARCHAR(100),
    classified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(table_name, column_name)
);

-- =============================================================================
-- PRIVACY_IMPACT_ASSESSMENTS — PIA tracking
-- =============================================================================
CREATE TABLE privacy_impact_assessments (
    id SERIAL PRIMARY KEY,
    feature_name VARCHAR(255) NOT NULL,
    description TEXT,
    team VARCHAR(100),
    assessor VARCHAR(100),

    -- Risk dimensions
    data_types_collected TEXT,
    purpose TEXT,
    third_party_sharing BOOLEAN DEFAULT FALSE,
    cross_border_transfer BOOLEAN DEFAULT FALSE,
    automated_decision_making BOOLEAN DEFAULT FALSE,
    risk_score INTEGER CHECK (risk_score >= 1 AND risk_score <= 5),

    status VARCHAR(20) DEFAULT 'draft'
        CHECK (status IN ('draft', 'in_review', 'approved', 'rejected', 'expired')),

    approved_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- =============================================================================
-- DATA_RETENTION_POLICIES — Retention rules per data category
-- =============================================================================
CREATE TABLE data_retention_policies (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    retention_days INTEGER NOT NULL,
    description TEXT,
    legal_basis TEXT,
    purge_strategy VARCHAR(20) DEFAULT 'hard_delete'
        CHECK (purge_strategy IN ('hard_delete', 'soft_delete', 'anonymize')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- PURGE_AUDIT_LOG — Tracks every purge operation for compliance
-- =============================================================================
CREATE TABLE purge_audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    records_affected INTEGER NOT NULL,
    purge_strategy VARCHAR(20) NOT NULL,
    purge_reason TEXT,
    executed_by VARCHAR(100) DEFAULT 'system',
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- SEED DATA
-- =============================================================================

-- ── Users (50 sample users with realistic PII) ──────────────────────────────
INSERT INTO users (
    first_name, last_name, email, phone, ssn, date_of_birth,
    street_address, city, state, zip_code, country,
    account_status, signup_source, created_at, last_login_at,
    consent_marketing, consent_analytics
)
SELECT
    (ARRAY['Alice','Bob','Carol','David','Eve','Frank','Grace','Hank',
           'Ivy','Jack','Karen','Leo','Mia','Noah','Olivia','Pete',
           'Quinn','Rosa','Sam','Tina'])[((i - 1) % 20) + 1],
    (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller',
           'Davis','Rodriguez','Martinez','Hernandez','Lopez','Gonzalez',
           'Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin'])[((i - 1) % 20) + 1],
    'user' || i || '@example.com',
    '+1-555-' || LPAD((1000 + i)::text, 4, '0'),
    LPAD((100 + (i * 7) % 900)::text, 3, '0') || '-' ||
        LPAD(((i * 13) % 100)::text, 2, '0') || '-' ||
        LPAD(((i * 37) % 10000)::text, 4, '0'),
    DATE '1970-01-01' + (i * 137 % 15000) * INTERVAL '1 day',
    (100 + i * 3)::text || ' ' ||
        (ARRAY['Main St','Oak Ave','Elm St','Park Blvd','Cedar Ln',
               'Pine Rd','Maple Dr','Birch Way'])[((i - 1) % 8) + 1],
    (ARRAY['Seattle','Portland','San Francisco','New York','Austin',
           'Denver','Chicago','Boston','Miami','Atlanta'])[((i - 1) % 10) + 1],
    (ARRAY['WA','OR','CA','NY','TX','CO','IL','MA','FL','GA'])[((i - 1) % 10) + 1],
    LPAD((10000 + i * 111 % 90000)::text, 5, '0'),
    'US',
    (ARRAY['active','active','active','active','suspended','deleted'])[((i - 1) % 6) + 1],
    (ARRAY['web','mobile','referral','social','organic'])[((i - 1) % 5) + 1],
    NOW() - ((50 - i) * INTERVAL '7 days'),
    NOW() - ((i % 30) * INTERVAL '1 day'),
    (i % 3 = 0),
    (i % 5 != 0)
FROM generate_series(1, 50) AS i;

-- ── Payment Methods ──────────────────────────────────────────────────────────
INSERT INTO payment_methods (user_id, card_number_encrypted, card_last_four, card_brand, expiry_month, expiry_year, billing_zip, is_default)
SELECT
    i,
    encode(sha256(('card-' || i)::bytea), 'hex'),
    LPAD((1000 + i * 37 % 9000)::text, 4, '0'),
    (ARRAY['Visa','Mastercard','Amex','Discover'])[((i - 1) % 4) + 1],
    ((i * 3) % 12) + 1,
    2025 + (i % 4),
    LPAD((10000 + i * 111 % 90000)::text, 5, '0'),
    TRUE
FROM generate_series(1, 40) AS i;

-- ── Orders ───────────────────────────────────────────────────────────────────
INSERT INTO orders (
    user_id, order_number, shipping_name, shipping_address,
    shipping_city, shipping_state, shipping_zip, shipping_country,
    subtotal, tax, total, status, created_at
)
SELECT
    ((i - 1) % 50) + 1,
    'ORD-' || LPAD(i::text, 6, '0'),
    u.first_name || ' ' || u.last_name,
    u.street_address,
    u.city, u.state, u.zip_code, u.country,
    (20 + (i * 17) % 480)::decimal(10,2),
    ((20 + (i * 17) % 480) * 0.08)::decimal(10,2),
    ((20 + (i * 17) % 480) * 1.08)::decimal(10,2),
    (ARRAY['pending','shipped','delivered','delivered','cancelled'])[((i - 1) % 5) + 1],
    NOW() - ((200 - i) * INTERVAL '1 day')
FROM generate_series(1, 200) AS i
JOIN users u ON u.id = ((i - 1) % 50) + 1;

-- ── Support Tickets (some contain PII in free-text) ──────────────────────────
INSERT INTO support_tickets (user_id, subject, description, internal_notes, priority, status, created_at)
VALUES
    (1, 'Cannot reset password',
     'Hi, my name is Alice Smith and I cannot reset my password. My email is alice.real@gmail.com and phone is 555-0101. Please help!',
     'Verified identity via SSN last 4: 1234. Reset link sent.',
     'high', 'resolved', NOW() - INTERVAL '30 days'),
    (5, 'Wrong shipping address',
     'Please update my address to 742 Evergreen Terrace, Springfield IL 62704. My order ORD-000005 shipped to wrong place.',
     'Customer provided new address. CC number ends in 4242.',
     'medium', 'open', NOW() - INTERVAL '15 days'),
    (12, 'Billing question',
     'I see a charge of $149.99 on my Visa ending 8901. My DOB is 03/15/1985 for verification. Can you explain this charge?',
     NULL,
     'low', 'open', NOW() - INTERVAL '5 days'),
    (20, 'Account deletion request',
     'I want to delete my account per GDPR. My full name is Tina Martin, email tina.m@gmail.com, SSN 456-78-9012.',
     'GDPR deletion request. Must complete within 30 days. Legal hold check required.',
     'high', 'open', NOW() - INTERVAL '2 days'),
    (8, 'Refund request',
     'Please refund order ORD-000008. The product was damaged.',
     'Refund approved. Customer Hank Davis, card ending 2345.',
     'medium', 'resolved', NOW() - INTERVAL '45 days');

-- ── Activity Log (behavioral tracking data) ──────────────────────────────────
INSERT INTO activity_log (user_id, action, resource_type, resource_id, ip_address, user_agent, geo_country, geo_city, created_at)
SELECT
    ((i - 1) % 50) + 1,
    (ARRAY['page_view','click','search','purchase','login','logout',
           'profile_update','password_change'])[((i - 1) % 8) + 1],
    (ARRAY['product','category','page','order'])[((i - 1) % 4) + 1],
    (i * 7) % 200 + 1,
    '192.168.' || ((i % 255))::text || '.' || ((i * 3 % 255))::text,
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    (ARRAY['US','US','US','CA','UK','DE','FR','JP'])[((i - 1) % 8) + 1],
    (ARRAY['Seattle','Portland','San Francisco','Toronto','London',
           'Berlin','Paris','Tokyo'])[((i - 1) % 8) + 1],
    NOW() - ((500 - i) * INTERVAL '1 hour')
FROM generate_series(1, 500) AS i;

-- ── Pre-populated Data Classification Registry ───────────────────────────────
INSERT INTO data_classification_registry (table_name, column_name, classification, pii_type, notes, classified_by) VALUES
    ('users', 'first_name',      'confidential', 'name',         'Can identify a person when combined with last name', 'privacy-team'),
    ('users', 'last_name',       'confidential', 'name',         'Can identify a person when combined with first name', 'privacy-team'),
    ('users', 'email',           'confidential', 'email',        'Direct personal identifier', 'privacy-team'),
    ('users', 'phone',           'confidential', 'phone',        'Direct personal identifier', 'privacy-team'),
    ('users', 'ssn',             'restricted',   'government_id','Highest sensitivity — Social Security Number', 'privacy-team'),
    ('users', 'date_of_birth',   'restricted',   'dob',          'Quasi-identifier, restricted when combined with other fields', 'privacy-team'),
    ('users', 'street_address',  'confidential', 'address',      'Location data — identifies residence', 'privacy-team'),
    ('users', 'city',            'internal',     'location',     'General location, low sensitivity alone', 'privacy-team'),
    ('users', 'state',           'internal',     'location',     'General location, low sensitivity alone', 'privacy-team'),
    ('users', 'zip_code',        'confidential', 'location',     'Can narrow to ~30k people, sensitive when combined', 'privacy-team'),
    ('users', 'account_status',  'internal',     NULL,           'Operational metadata', 'privacy-team'),
    ('users', 'created_at',      'internal',     NULL,           'Operational metadata', 'privacy-team'),
    ('payment_methods', 'card_number_encrypted', 'restricted', 'financial', 'PCI DSS scope — encrypted at rest', 'privacy-team'),
    ('payment_methods', 'card_last_four',        'confidential','financial', 'Partial card number for display', 'privacy-team'),
    ('orders', 'shipping_name',    'confidential', 'name',    'Duplicated PII from users table', 'privacy-team'),
    ('orders', 'shipping_address', 'confidential', 'address', 'Duplicated PII from users table', 'privacy-team'),
    ('activity_log', 'ip_address',  'confidential', 'network', 'Can identify a user via ISP records', 'privacy-team'),
    ('activity_log', 'user_agent',  'internal',     'device',  'Browser fingerprinting risk when combined', 'privacy-team'),
    ('activity_log', 'geo_city',    'confidential', 'location','Derived from IP, can pinpoint user', 'privacy-team'),
    ('support_tickets', 'description',    'confidential', 'free_text', 'Often contains PII accidentally', 'privacy-team'),
    ('support_tickets', 'internal_notes', 'restricted',   'free_text', 'Agents may paste sensitive data', 'privacy-team');

-- ── Sample Data Retention Policies ───────────────────────────────────────────
INSERT INTO data_retention_policies (table_name, retention_days, description, legal_basis, purge_strategy) VALUES
    ('activity_log',    90,  'Behavioral logs kept 90 days', 'Legitimate interest — analytics', 'hard_delete'),
    ('support_tickets', 365, 'Support tickets kept 1 year after resolution', 'Contract fulfillment', 'anonymize'),
    ('orders',          2555,'Order history kept 7 years for tax compliance', 'Legal obligation — tax law', 'anonymize'),
    ('payment_methods', 0,   'Deleted immediately when user removes card', 'Consent withdrawal', 'hard_delete'),
    ('users',           30,  'Deleted accounts purged after 30-day grace period', 'GDPR Art. 17 — right to erasure', 'hard_delete');

-- ── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(account_status);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_created ON orders(created_at);
CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_created ON activity_log(created_at);
CREATE INDEX idx_tickets_user ON support_tickets(user_id);
CREATE INDEX idx_tickets_status ON support_tickets(status);
CREATE INDEX idx_classification_table ON data_classification_registry(table_name);
CREATE INDEX idx_retention_table ON data_retention_policies(table_name);
CREATE INDEX idx_purge_audit_table ON purge_audit_log(table_name);
