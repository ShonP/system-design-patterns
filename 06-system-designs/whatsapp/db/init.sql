-- =============================================================
-- WhatsApp System Design Lab — Database Schema
-- =============================================================
-- This schema models the core data model for a WhatsApp-like
-- messaging system: users, chats, messages, an inbox for
-- offline delivery, and read receipts.
-- =============================================================

-- Users who can send and receive messages
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    public_key TEXT,  -- for end-to-end encryption demos
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- A chat can be 1:1 (is_group = false) or a group (is_group = true)
CREATE TABLE chats (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200),          -- NULL for 1:1 chats, set for groups
    is_group BOOLEAN DEFAULT FALSE,
    created_by INTEGER REFERENCES users(id),
    max_participants INTEGER DEFAULT 100,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Which users belong to which chats
CREATE TABLE chat_participants (
    chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member',  -- 'admin' or 'member'
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (chat_id, user_id)
);

-- Every message ever sent (the "Message table" from the design)
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER REFERENCES chats(id),
    sender_id INTEGER REFERENCES users(id),
    content TEXT,                          -- plaintext content
    encrypted_content TEXT,                -- for E2E encryption demos
    message_type VARCHAR(50) DEFAULT 'text',  -- text, image, etc.
    sequence_number BIGINT,               -- per-chat ordering
    client_message_id TEXT,               -- idempotency key minted by the sender
    server_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Idempotency: a client that never saw its ACK will retry the SAME
-- client_message_id. This index turns that retry into a no-op instead of a
-- duplicate message. Partial, so pre-existing/plaintext rows with NULL are
-- unconstrained (Postgres would allow unlimited NULLs anyway; the WHERE
-- clause keeps the index small).
CREATE UNIQUE INDEX idx_messages_client_msg_id
    ON messages (sender_id, client_message_id)
    WHERE client_message_id IS NOT NULL;

-- The "Inbox" — one row per recipient per message.
-- The row is NOT deleted on ACK; its status advances
-- pending -> delivered -> read (monotone, never backwards).
-- A real system would archive/prune rows that reached 'read'.
CREATE TABLE inbox (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    message_id INTEGER REFERENCES messages(id),
    status VARCHAR(20) DEFAULT 'pending',  -- pending / delivered / read
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sequence counters — one per chat, used to detect gaps
CREATE TABLE chat_sequences (
    chat_id INTEGER PRIMARY KEY REFERENCES chats(id),
    last_sequence BIGINT DEFAULT 0
);

-- =============================================================
-- Indexes for common query patterns
-- =============================================================
CREATE INDEX idx_chat_participants_user ON chat_participants(user_id);
CREATE INDEX idx_messages_chat ON messages(chat_id, sequence_number);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_inbox_user_status ON inbox(user_id, status);
CREATE INDEX idx_inbox_message ON inbox(message_id);

-- =============================================================
-- Seed data — five demo users
-- =============================================================
INSERT INTO users (username, display_name) VALUES
    ('alice',   'Alice Johnson'),
    ('bob',     'Bob Smith'),
    ('charlie', 'Charlie Brown'),
    ('diana',   'Diana Prince'),
    ('eve',     'Eve Wilson');

-- Two 1:1 chats and one group chat
INSERT INTO chats (name, is_group, created_by) VALUES
    (NULL,          FALSE, 1),   -- chat 1: Alice ↔ Bob
    (NULL,          FALSE, 1),   -- chat 2: Alice ↔ Charlie
    ('Study Group', TRUE,  1);   -- chat 3: group

-- Participants
INSERT INTO chat_participants (chat_id, user_id, role) VALUES
    (1, 1, 'member'), (1, 2, 'member'),              -- Alice & Bob
    (2, 1, 'member'), (2, 3, 'member'),              -- Alice & Charlie
    (3, 1, 'admin'),  (3, 2, 'member'),              -- Study Group
    (3, 3, 'member'), (3, 4, 'member');

-- Sequence counters
INSERT INTO chat_sequences (chat_id, last_sequence) VALUES
    (1, 3), (2, 2), (3, 3);

-- Sample messages
INSERT INTO messages (chat_id, sender_id, content, sequence_number) VALUES
    (1, 1, 'Hey Bob! How are you?',               1),
    (1, 2, 'Hi Alice! Doing great, thanks!',      2),
    (1, 1, 'Want to grab coffee later?',           3),
    (2, 1, 'Hey Charlie!',                         1),
    (2, 3, 'Hi Alice! What''s up?',                2),
    (3, 1, 'Welcome to the study group everyone!', 1),
    (3, 2, 'Thanks for creating this!',            2),
    (3, 3, 'Happy to be here!',                    3);

-- Undelivered inbox entries (simulating offline users)
INSERT INTO inbox (user_id, message_id, status) VALUES
    (2, 3, 'pending'),   -- Bob hasn't received Alice's coffee message
    (4, 6, 'pending'),   -- Diana hasn't received the group welcome
    (4, 7, 'pending'),
    (4, 8, 'pending');
