-- ============================================================
-- Dropbox System Design Lab — Database Schema
-- ============================================================
-- This schema models the metadata layer of a Dropbox-like
-- file storage service.  The actual file bytes live in object
-- storage (MinIO / S3); Postgres only tracks metadata.
-- ============================================================

-- Users of the system
CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    email       VARCHAR(255) UNIQUE NOT NULL,
    username    VARCHAR(100) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Every file (or folder) a user owns
CREATE TABLE files (
    id              SERIAL PRIMARY KEY,
    owner_id        INTEGER NOT NULL REFERENCES users(id),
    file_name       VARCHAR(255) NOT NULL,
    mime_type       VARCHAR(100),
    file_size       BIGINT DEFAULT 0,           -- bytes
    fingerprint     VARCHAR(64),                -- SHA-256 of full content
    storage_key     VARCHAR(512),               -- key inside the S3/MinIO bucket
    status          VARCHAR(20) DEFAULT 'uploading'
                        CHECK (status IN ('uploading','uploaded','failed')),
    version         INTEGER DEFAULT 1,
    parent_id       INTEGER REFERENCES files(id), -- for folder hierarchy
    is_folder       BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Individual chunks that make up a file upload
CREATE TABLE chunks (
    id              SERIAL PRIMARY KEY,
    file_id         INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    chunk_index     INTEGER NOT NULL,           -- 0-based order
    chunk_size      BIGINT NOT NULL,
    fingerprint     VARCHAR(64) NOT NULL,       -- SHA-256 of chunk content
    storage_key     VARCHAR(512),               -- key inside the bucket
    etag            VARCHAR(128),               -- returned by S3 after upload
    status          VARCHAR(20) DEFAULT 'pending'
                        CHECK (status IN ('pending','uploading','uploaded','failed')),
    uploaded_at     TIMESTAMP,
    UNIQUE (file_id, chunk_index)
);

-- Tracks which files are shared with which users
CREATE TABLE shared_files (
    id              SERIAL PRIMARY KEY,
    file_id         INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    shared_with     INTEGER NOT NULL REFERENCES users(id),
    permission      VARCHAR(10) DEFAULT 'read'
                        CHECK (permission IN ('read','write')),
    shared_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (file_id, shared_with)
);

-- Simple sync log: every mutation is an event clients can poll
CREATE TABLE sync_events (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id),
    file_id         INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    event_type      VARCHAR(20) NOT NULL
                        CHECK (event_type IN ('created','updated','deleted','shared')),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes for the query patterns used in the notebooks
-- ============================================================
CREATE INDEX idx_files_owner       ON files(owner_id);
CREATE INDEX idx_files_fingerprint ON files(fingerprint);
CREATE INDEX idx_files_parent      ON files(parent_id);
CREATE INDEX idx_chunks_file       ON chunks(file_id);
CREATE INDEX idx_shared_file       ON shared_files(file_id);
CREATE INDEX idx_shared_user       ON shared_files(shared_with);
CREATE INDEX idx_sync_user_time    ON sync_events(user_id, created_at);

-- ============================================================
-- Seed data — a handful of users to play with
-- ============================================================
INSERT INTO users (email, username) VALUES
    ('alice@example.com',   'alice'),
    ('bob@example.com',     'bob'),
    ('charlie@example.com', 'charlie');
