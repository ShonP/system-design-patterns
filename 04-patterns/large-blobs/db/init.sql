CREATE TABLE files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    filename VARCHAR(255) NOT NULL,
    size_bytes BIGINT,
    content_type VARCHAR(100),
    storage_key VARCHAR(500),
    status VARCHAR(50) DEFAULT 'pending',
    upload_id VARCHAR(500),
    parts_completed INTEGER DEFAULT 0,
    total_parts INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE upload_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id UUID REFERENCES files(id) ON DELETE CASCADE,
    part_number INTEGER NOT NULL,
    etag VARCHAR(255),
    size_bytes BIGINT,
    uploaded_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(file_id, part_number)
);

CREATE TABLE download_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id UUID REFERENCES files(id),
    user_id UUID,
    ip_address VARCHAR(45),
    bytes_downloaded BIGINT,
    downloaded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_files_user_id ON files(user_id);
CREATE INDEX idx_files_status ON files(status);
CREATE INDEX idx_files_storage_key ON files(storage_key);
CREATE INDEX idx_upload_parts_file_id ON upload_parts(file_id);

INSERT INTO files (user_id, filename, size_bytes, content_type, storage_key, status)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'sample.txt', 1024, 'text/plain', 'uploads/user1/sample.txt', 'completed'),
    ('11111111-1111-1111-1111-111111111111', 'photo.jpg', 2048000, 'image/jpeg', 'uploads/user1/photo.jpg', 'completed');
