-- ============================================================
-- GDPR Paired Regions Lab — Seed Data
-- This schema is loaded into BOTH region databases (EU-West
-- and EU-North) by docker-compose.  The notebooks will then
-- manipulate the data to demonstrate residency, replication,
-- erasure, and auditing patterns.
-- ============================================================

-- ── Users table (contains PII) ───────────────────────────────
-- PII = Personally Identifiable Information: any data that can
-- identify a specific person.  Under GDPR every column below
-- except 'id' and 'created_at' is PII.
CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) UNIQUE NOT NULL,       -- PII
    full_name       VARCHAR(255) NOT NULL,              -- PII
    phone           VARCHAR(50),                        -- PII
    date_of_birth   DATE,                               -- PII
    country_code    VARCHAR(2) NOT NULL,                -- used for geo-routing
    home_region     VARCHAR(50) NOT NULL,               -- eu-west | eu-north
    consent_given   BOOLEAN DEFAULT FALSE,              -- GDPR consent flag
    consent_date    TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Addresses table (PII) ────────────────────────────────────
CREATE TABLE addresses (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE,
    street      VARCHAR(255) NOT NULL,                  -- PII
    city        VARCHAR(100) NOT NULL,                  -- PII
    postal_code VARCHAR(20) NOT NULL,                   -- PII
    country     VARCHAR(100) NOT NULL,
    is_primary  BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Orders table (linked to users) ──────────────────────────
CREATE TABLE orders (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE,
    product     VARCHAR(255) NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    currency    VARCHAR(3) DEFAULT 'EUR',
    status      VARCHAR(50) DEFAULT 'completed',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Consent log (audit trail for GDPR) ──────────────────────
-- GDPR requires you to prove WHEN and HOW a user gave consent.
CREATE TABLE consent_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE,
    action      VARCHAR(50) NOT NULL,   -- granted | revoked | updated
    purpose     VARCHAR(255) NOT NULL,  -- marketing | analytics | essential
    ip_address  VARCHAR(45),
    user_agent  TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Erasure requests (GDPR Article 17 tracking) ─────────────
CREATE TABLE erasure_requests (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL,
    user_email      VARCHAR(255) NOT NULL,
    reason          TEXT,
    status          VARCHAR(50) DEFAULT 'pending',  -- pending | processing | completed | denied
    requested_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at    TIMESTAMP,
    completed_by    VARCHAR(100)
);

-- ── Data residency audit log ─────────────────────────────────
-- Records every cross-region data movement for compliance.
CREATE TABLE data_residency_log (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER,
    action          VARCHAR(50) NOT NULL,   -- write | replicate | delete | access
    source_region   VARCHAR(50) NOT NULL,
    target_region   VARCHAR(50),
    table_name      VARCHAR(100) NOT NULL,
    record_id       INTEGER,
    reason          TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_users_country ON users(country_code);
CREATE INDEX idx_users_region ON users(home_region);
CREATE INDEX idx_addresses_user ON addresses(user_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_consent_log_user ON consent_log(user_id);
CREATE INDEX idx_erasure_requests_user ON erasure_requests(user_id);
CREATE INDEX idx_residency_log_user ON data_residency_log(user_id);

-- ============================================================
-- Seed Data — Sample EU Citizens
-- ============================================================

-- EU-West users (Netherlands, Belgium, France, Germany)
INSERT INTO users (email, full_name, phone, date_of_birth, country_code, home_region, consent_given, consent_date) VALUES
('anna.devries@example.nl',     'Anna de Vries',      '+31-6-1234-5678',  '1990-03-15', 'NL', 'eu-west',  TRUE,  '2024-01-10 09:00:00'),
('marc.dupont@example.be',      'Marc Dupont',        '+32-2-555-0123',   '1985-07-22', 'BE', 'eu-west',  TRUE,  '2024-02-14 14:30:00'),
('claire.martin@example.fr',    'Claire Martin',      '+33-1-4567-8901',  '1992-11-08', 'FR', 'eu-west',  TRUE,  '2024-03-01 11:00:00'),
('hans.mueller@example.de',     'Hans Müller',        '+49-30-9876-5432', '1978-05-30', 'DE', 'eu-west',  TRUE,  '2024-01-20 16:45:00'),
('sophie.jansen@example.nl',    'Sophie Jansen',      '+31-6-8765-4321',  '1995-09-12', 'NL', 'eu-west',  FALSE, NULL),
('pierre.leblanc@example.fr',   'Pierre Leblanc',     '+33-6-1111-2222',  '1988-12-25', 'FR', 'eu-west',  TRUE,  '2024-04-05 08:15:00'),
('lena.schmidt@example.de',     'Lena Schmidt',       '+49-89-3333-4444', '1993-02-18', 'DE', 'eu-west',  TRUE,  '2024-02-28 10:00:00'),
('jan.bakker@example.nl',       'Jan Bakker',         '+31-6-5555-6666',  '1982-08-04', 'NL', 'eu-west',  TRUE,  '2024-03-15 13:20:00');

-- EU-North users (Ireland, Sweden, Finland, Denmark)
INSERT INTO users (email, full_name, phone, date_of_birth, country_code, home_region, consent_given, consent_date) VALUES
('aoife.murphy@example.ie',     'Aoife Murphy',       '+353-1-234-5678',  '1991-06-20', 'IE', 'eu-north', TRUE,  '2024-01-05 10:30:00'),
('erik.lindgren@example.se',    'Erik Lindgren',      '+46-8-555-0199',   '1987-04-11', 'SE', 'eu-north', TRUE,  '2024-02-20 09:00:00'),
('mika.virtanen@example.fi',    'Mika Virtanen',      '+358-9-876-5432',  '1994-01-29', 'FI', 'eu-north', TRUE,  '2024-03-10 15:45:00'),
('lars.nielsen@example.dk',     'Lars Nielsen',       '+45-33-12-3456',   '1980-10-03', 'DK', 'eu-north', TRUE,  '2024-01-25 11:00:00'),
('siobhan.kelly@example.ie',    'Siobhán Kelly',      '+353-1-987-6543',  '1996-07-14', 'IE', 'eu-north', FALSE, NULL),
('astrid.berg@example.se',      'Astrid Berg',        '+46-31-222-3333',  '1989-03-08', 'SE', 'eu-north', TRUE,  '2024-04-01 14:00:00'),
('emma.korhonen@example.fi',    'Emma Korhonen',      '+358-40-111-2222', '1993-11-22', 'FI', 'eu-north', TRUE,  '2024-02-10 08:30:00');

-- Addresses
INSERT INTO addresses (user_id, street, city, postal_code, country) VALUES
(1,  'Keizersgracht 42',       'Amsterdam',    '1015 CR',  'Netherlands'),
(2,  'Rue de la Loi 16',       'Brussels',     '1000',     'Belgium'),
(3,  'Rue de Rivoli 75',       'Paris',        '75001',    'France'),
(4,  'Unter den Linden 77',    'Berlin',       '10117',    'Germany'),
(5,  'Prinsengracht 263',      'Amsterdam',    '1016 GV',  'Netherlands'),
(6,  'Avenue des Champs 8',    'Paris',        '75008',    'France'),
(7,  'Marienplatz 1',          'Munich',       '80331',    'Germany'),
(8,  'Damrak 1',               'Amsterdam',    '1012 LG',  'Netherlands'),
(9,  'Grafton Street 12',      'Dublin',       'D02 VR66', 'Ireland'),
(10, 'Drottninggatan 53',      'Stockholm',    '111 21',   'Sweden'),
(11, 'Mannerheimintie 20',     'Helsinki',     '00100',    'Finland'),
(12, 'Strøget 1',              'Copenhagen',   '1160',     'Denmark'),
(13, 'O''Connell Street 5',    'Dublin',       'D01 E9X0', 'Ireland'),
(14, 'Kungsgatan 44',          'Gothenburg',   '411 15',   'Sweden'),
(15, 'Aleksanterinkatu 52',    'Helsinki',     '00100',    'Finland');

-- Orders
INSERT INTO orders (user_id, product, amount, currency, status, created_at) VALUES
(1,  'Azure Cloud Subscription',    299.99, 'EUR', 'completed', '2024-06-01 10:00:00'),
(1,  'Surface Laptop 5',           1299.00, 'EUR', 'completed', '2024-07-15 14:30:00'),
(2,  'Microsoft 365 Business',       99.99, 'EUR', 'completed', '2024-05-20 09:00:00'),
(3,  'Xbox Game Pass Ultimate',       14.99, 'EUR', 'completed', '2024-08-01 16:00:00'),
(4,  'Visual Studio Enterprise',    5999.00, 'EUR', 'completed', '2024-04-10 11:30:00'),
(5,  'Azure DevOps Services',        30.00, 'EUR', 'pending',   '2024-09-01 08:45:00'),
(9,  'Power BI Pro',                  9.99, 'EUR', 'completed', '2024-06-15 13:00:00'),
(10, 'GitHub Enterprise',            21.00, 'EUR', 'completed', '2024-07-01 10:30:00'),
(11, 'Azure Cosmos DB',             249.99, 'EUR', 'completed', '2024-08-20 15:00:00'),
(12, 'Dynamics 365 Sales',          649.99, 'EUR', 'completed', '2024-05-05 09:30:00'),
(3,  'Surface Pro 9',              1199.00, 'EUR', 'completed', '2024-09-10 12:00:00'),
(7,  'Azure Kubernetes Service',    499.99, 'EUR', 'completed', '2024-07-22 14:00:00');

-- Consent log entries
INSERT INTO consent_log (user_id, action, purpose, ip_address, created_at) VALUES
(1,  'granted', 'essential',    '82.168.1.100',  '2024-01-10 09:00:00'),
(1,  'granted', 'marketing',    '82.168.1.100',  '2024-01-10 09:00:05'),
(1,  'granted', 'analytics',    '82.168.1.100',  '2024-01-10 09:00:10'),
(2,  'granted', 'essential',    '91.176.2.50',   '2024-02-14 14:30:00'),
(2,  'granted', 'analytics',    '91.176.2.50',   '2024-02-14 14:30:05'),
(3,  'granted', 'essential',    '176.150.3.200', '2024-03-01 11:00:00'),
(3,  'granted', 'marketing',    '176.150.3.200', '2024-03-01 11:00:05'),
(5,  'revoked', 'marketing',    '82.168.5.75',   '2024-06-01 12:00:00'),
(9,  'granted', 'essential',    '86.45.9.10',    '2024-01-05 10:30:00'),
(9,  'granted', 'analytics',    '86.45.9.10',    '2024-01-05 10:30:05'),
(10, 'granted', 'essential',    '78.67.10.20',   '2024-02-20 09:00:00'),
(13, 'revoked', 'analytics',    '86.45.13.30',   '2024-07-01 16:00:00');
