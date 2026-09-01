-- =============================================================
-- Google Docs System Design Lab — Database Schema
-- =============================================================
-- This schema models the core data model for a Google Docs-like
-- collaborative document editor: users, documents, operations
-- (for OT), document versions/snapshots, and cursor presence.
-- =============================================================

-- Users who can create and edit documents
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    color VARCHAR(7) DEFAULT '#3B82F6',  -- cursor color for presence
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Documents — metadata about each document
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL DEFAULT 'Untitled Document',
    owner_id INTEGER REFERENCES users(id),
    current_version INTEGER DEFAULT 0,   -- latest snapshot version
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Operations — the append-only log of edits (used by OT)
-- Each operation is relative to a specific document version.
CREATE TABLE operations (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    version INTEGER NOT NULL,            -- the doc version this op was created against
    op_type VARCHAR(20) NOT NULL,        -- 'insert' or 'delete'
    position INTEGER NOT NULL,           -- character position in the document
    content TEXT DEFAULT '',             -- the text inserted (empty for delete)
    length INTEGER DEFAULT 0,           -- number of chars deleted (0 for insert)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Snapshots — periodic compactions of operations into full document text
-- Used for versioning and efficient document loading
CREATE TABLE snapshots (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    content TEXT NOT NULL DEFAULT '',     -- full document text at this version
    op_count INTEGER DEFAULT 0,          -- how many ops were compacted
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(document_id, version)
);

-- Document collaborators — who has access to which document
CREATE TABLE collaborators (
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'editor',   -- 'owner', 'editor', 'viewer'
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (document_id, user_id)
);

-- =============================================================
-- Indexes for common query patterns
-- =============================================================
CREATE INDEX idx_operations_doc_version ON operations(document_id, version);
CREATE INDEX idx_operations_doc_created ON operations(document_id, created_at);
CREATE INDEX idx_snapshots_doc_version ON snapshots(document_id, version);
CREATE INDEX idx_collaborators_user ON collaborators(user_id);

-- =============================================================
-- Seed data
-- =============================================================

-- Five demo users with distinct cursor colors
INSERT INTO users (username, display_name, color) VALUES
    ('alice',   'Alice Johnson',  '#3B82F6'),  -- blue
    ('bob',     'Bob Smith',      '#EF4444'),  -- red
    ('charlie', 'Charlie Brown',  '#10B981'),  -- green
    ('diana',   'Diana Prince',   '#F59E0B'),  -- amber
    ('eve',     'Eve Wilson',     '#8B5CF6');   -- purple

-- Three sample documents
INSERT INTO documents (title, owner_id, current_version) VALUES
    ('Meeting Notes — Q1 Planning',  1, 1),
    ('Project Proposal Draft',       1, 1),
    ('Shared Shopping List',         2, 0);

-- Collaborators
INSERT INTO collaborators (document_id, user_id, role) VALUES
    (1, 1, 'owner'),   (1, 2, 'editor'),  (1, 3, 'editor'),
    (2, 1, 'owner'),   (2, 4, 'editor'),
    (3, 2, 'owner'),   (3, 1, 'editor'),  (3, 3, 'viewer');

-- Initial snapshots (version 0 = empty, version 1 = first save)
INSERT INTO snapshots (document_id, version, content, op_count, created_by) VALUES
    (1, 0, '', 0, 1),
    (1, 1, E'Meeting Notes — Q1 Planning\n\nAttendees: Alice, Bob, Charlie\n\nAgenda:\n1. Review last quarter\n2. Set goals for Q1\n3. Assign action items\n\nNotes:\n- Revenue grew 15% last quarter\n- Need to hire 3 more engineers\n- Launch date moved to March 15', 11, 1),
    (2, 0, '', 0, 1),
    (2, 1, E'Project Proposal: Real-Time Collaboration Tool\n\nObjective:\nBuild a collaborative document editor that supports real-time editing by multiple users.\n\nKey Features:\n- Operational Transformation for conflict resolution\n- WebSocket-based real-time sync\n- Document versioning and history\n- Cursor presence and awareness', 8, 1),
    (3, 0, '', 0, 2);

-- Sample operations on document 1 (simulating collaborative editing).
-- Positions are the real character offsets at the time each op was created --
-- replaying them in order rebuilds snapshot v1 exactly (Notebook 1 asserts this).
INSERT INTO operations (document_id, user_id, version, op_type, position, content, length) VALUES
    (1, 1, 0, 'insert', 0, E'Meeting Notes', 0),
    (1, 1, 0, 'insert', 13, E' — Q1 Planning', 0),
    (1, 1, 0, 'insert', 27, E'\n\nAttendees: Alice', 0),
    (1, 2, 0, 'insert', 45, E', Bob', 0),
    (1, 3, 0, 'insert', 50, E', Charlie', 0),
    (1, 1, 0, 'insert', 59, E'\n\nAgenda:\n1. Review last quarter', 0),
    (1, 1, 0, 'insert', 91, E'\n2. Set goals for Q1', 0),
    (1, 1, 0, 'insert', 111, E'\n3. Assign action items', 0),
    (1, 2, 0, 'insert', 134, E'\n\nNotes:\n- Revenue grew 15% last quarter', 0),
    (1, 2, 0, 'insert', 174, E'\n- Need to hire 3 more engineers', 0),
    (1, 1, 0, 'insert', 206, E'\n- Launch date moved to March 15', 0);
