-- Payment System Lab Database
-- Models the core entities of a Stripe-like payment processor

-- ============================================================
-- Core Tables
-- ============================================================

-- Merchants: businesses that use our payment platform
CREATE TABLE merchants (
    id TEXT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    api_key TEXT UNIQUE NOT NULL,
    webhook_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment Intents: a merchant's intention to collect money from a customer.
-- This is the top-level object that tracks the full payment lifecycle.
CREATE TABLE payment_intents (
    id TEXT PRIMARY KEY,
    merchant_id TEXT NOT NULL REFERENCES merchants(id),
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'usd',
    description TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'created',
    idempotency_key TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (merchant_id, idempotency_key)
);

-- Transactions: individual money-movement records linked to a PaymentIntent.
-- One PaymentIntent can have many Transactions (retries, refunds, etc.).
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    payment_intent_id TEXT NOT NULL REFERENCES payment_intents(id),
    type VARCHAR(20) NOT NULL DEFAULT 'charge',
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'usd',
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    card_last_four VARCHAR(4),
    card_brand VARCHAR(20),
    network_reference_id TEXT,
    failure_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ledger Entries: double-entry bookkeeping records.
-- Every money movement creates TWO rows: one debit and one credit.
-- The sum of all debits must always equal the sum of all credits.
CREATE TABLE ledger_entries (
    id SERIAL PRIMARY KEY,
    transaction_id TEXT NOT NULL REFERENCES transactions(id),
    account_name TEXT NOT NULL,
    entry_type VARCHAR(6) NOT NULL CHECK (entry_type IN ('debit', 'credit')),
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'usd',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment Audit Log: append-only history of every state change
CREATE TABLE payment_audit_log (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(30) NOT NULL,
    entity_id TEXT NOT NULL,
    old_status VARCHAR(30),
    new_status VARCHAR(30),
    changed_by VARCHAR(100) NOT NULL DEFAULT 'system',
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fraud Signals: simple feature store for fraud detection
CREATE TABLE fraud_signals (
    id SERIAL PRIMARY KEY,
    transaction_id TEXT NOT NULL REFERENCES transactions(id),
    signal_name VARCHAR(100) NOT NULL,
    signal_value NUMERIC,
    flagged BOOLEAN DEFAULT FALSE,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_payment_intents_merchant ON payment_intents(merchant_id);
CREATE INDEX idx_payment_intents_status ON payment_intents(status);
CREATE INDEX idx_payment_intents_idempotency ON payment_intents(merchant_id, idempotency_key);
CREATE INDEX idx_transactions_intent ON transactions(payment_intent_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_ledger_transaction ON ledger_entries(transaction_id);
CREATE INDEX idx_ledger_account ON ledger_entries(account_name);
CREATE INDEX idx_audit_entity ON payment_audit_log(entity_type, entity_id);
CREATE INDEX idx_fraud_transaction ON fraud_signals(transaction_id);

-- ============================================================
-- Seed Data
-- ============================================================

-- Sample merchants
INSERT INTO merchants (id, name, email, api_key) VALUES
    ('merch_001', 'Acme Online Store', 'billing@acme.example.com', 'pk_live_acme_abc123'),
    ('merch_002', 'Widget Co', 'pay@widget.example.com', 'pk_live_widget_def456'),
    ('merch_003', 'Book Haven', 'finance@bookhaven.example.com', 'pk_live_books_ghi789');

-- Sample payment intents in various states
INSERT INTO payment_intents (id, merchant_id, amount_cents, currency, description, status, idempotency_key) VALUES
    ('pi_001', 'merch_001', 4999, 'usd', 'Order #1001 - Wireless headphones', 'succeeded', 'order-1001'),
    ('pi_002', 'merch_001', 1299, 'usd', 'Order #1002 - Phone case', 'succeeded', 'order-1002'),
    ('pi_003', 'merch_002', 24999, 'usd', 'Invoice #5001 - Premium widget', 'succeeded', 'inv-5001'),
    ('pi_004', 'merch_002', 7500, 'usd', 'Invoice #5002 - Widget bundle', 'failed', 'inv-5002'),
    ('pi_005', 'merch_003', 1599, 'usd', 'Order #301 - Programming book', 'created', 'order-301'),
    ('pi_006', 'merch_001', 9999, 'usd', 'Order #1003 - Smart speaker', 'processing', 'order-1003'),
    ('pi_007', 'merch_003', 3499, 'usd', 'Order #302 - Book bundle', 'succeeded', 'order-302'),
    ('pi_008', 'merch_001', 2499, 'usd', 'Order #1004 - USB cable', 'succeeded', 'order-1004'),
    ('pi_009', 'merch_002', 15000, 'usd', 'Invoice #5003 - Widget bulk', 'succeeded', 'inv-5003'),
    ('pi_010', 'merch_001', 4999, 'usd', 'Order #1005 - Headphones', 'succeeded', 'order-1005');

-- Sample transactions
INSERT INTO transactions (id, payment_intent_id, type, amount_cents, currency, status, card_last_four, card_brand, network_reference_id) VALUES
    ('txn_001', 'pi_001', 'charge', 4999, 'usd', 'succeeded', '4242', 'visa', 'net_ref_001'),
    ('txn_002', 'pi_002', 'charge', 1299, 'usd', 'succeeded', '4242', 'visa', 'net_ref_002'),
    ('txn_003', 'pi_003', 'charge', 24999, 'usd', 'succeeded', '5555', 'mastercard', 'net_ref_003'),
    ('txn_004', 'pi_004', 'charge', 7500, 'usd', 'failed', '1234', 'visa', 'net_ref_004'),
    ('txn_005', 'pi_006', 'charge', 9999, 'usd', 'pending', '4242', 'visa', NULL),
    ('txn_006', 'pi_007', 'charge', 3499, 'usd', 'succeeded', '9876', 'amex', 'net_ref_006'),
    ('txn_007', 'pi_008', 'charge', 2499, 'usd', 'succeeded', '4242', 'visa', 'net_ref_007'),
    ('txn_008', 'pi_009', 'charge', 15000, 'usd', 'succeeded', '5555', 'mastercard', 'net_ref_008');

-- Sample ledger entries (double-entry bookkeeping for succeeded transactions)
-- Rule: every charge debits "customer_receivable" and credits "merchant_payable"
INSERT INTO ledger_entries (transaction_id, account_name, entry_type, amount_cents, currency, description) VALUES
    ('txn_001', 'customer_receivable', 'debit',  4999, 'usd', 'Charge for pi_001'),
    ('txn_001', 'merchant_payable',    'credit', 4999, 'usd', 'Charge for pi_001'),
    ('txn_002', 'customer_receivable', 'debit',  1299, 'usd', 'Charge for pi_002'),
    ('txn_002', 'merchant_payable',    'credit', 1299, 'usd', 'Charge for pi_002'),
    ('txn_003', 'customer_receivable', 'debit',  24999, 'usd', 'Charge for pi_003'),
    ('txn_003', 'merchant_payable',    'credit', 24999, 'usd', 'Charge for pi_003'),
    ('txn_006', 'customer_receivable', 'debit',  3499, 'usd', 'Charge for pi_007'),
    ('txn_006', 'merchant_payable',    'credit', 3499, 'usd', 'Charge for pi_007'),
    ('txn_007', 'customer_receivable', 'debit',  2499, 'usd', 'Charge for pi_008'),
    ('txn_007', 'merchant_payable',    'credit', 2499, 'usd', 'Charge for pi_008'),
    ('txn_008', 'customer_receivable', 'debit',  15000, 'usd', 'Charge for pi_009'),
    ('txn_008', 'merchant_payable',    'credit', 15000, 'usd', 'Charge for pi_009');

-- Sample audit log entries
INSERT INTO payment_audit_log (entity_type, entity_id, old_status, new_status, changed_by, metadata) VALUES
    ('payment_intent', 'pi_001', NULL, 'created', 'payment_service', '{"amount_cents": 4999}'),
    ('payment_intent', 'pi_001', 'created', 'processing', 'payment_service', '{}'),
    ('payment_intent', 'pi_001', 'processing', 'succeeded', 'payment_service', '{"network_ref": "net_ref_001"}'),
    ('transaction', 'txn_001', NULL, 'pending', 'transaction_service', '{"card_brand": "visa"}'),
    ('transaction', 'txn_001', 'pending', 'succeeded', 'transaction_service', '{"auth_code": "AUTH001"}'),
    ('payment_intent', 'pi_004', NULL, 'created', 'payment_service', '{"amount_cents": 7500}'),
    ('payment_intent', 'pi_004', 'created', 'processing', 'payment_service', '{}'),
    ('payment_intent', 'pi_004', 'processing', 'failed', 'payment_service', '{"reason": "insufficient_funds"}'),
    ('transaction', 'txn_004', NULL, 'pending', 'transaction_service', '{"card_brand": "visa"}'),
    ('transaction', 'txn_004', 'pending', 'failed', 'transaction_service', '{"decline_code": "insufficient_funds"}');
