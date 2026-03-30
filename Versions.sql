USE my_app_db;
CREATE TABLE IF NOT EXISTS Versions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    document_id BIGINT NOT NULL,
    version_number INT NOT NULL,
    content TEXT,
    status ENUM('draft', 'pending_approval', 'approved', 'rejected') DEFAULT 'draft',
    parent_version_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    file_path VARCHAR(255),
    file_size BIGINT,
    checksum VARCHAR(255), -- Used to verify file integrity
    FOREIGN KEY (document_id) REFERENCES Documents(id),
    FOREIGN KEY (parent_version_id) REFERENCES Versions(id)
);