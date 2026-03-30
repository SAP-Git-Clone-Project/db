USE my_app_db;
CREATE TABLE IF NOT EXISTS Document_Permissions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    document_id BIGINT NOT NULL,
    permission_type ENUM('read', 'write', 'delete', 'approve') NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(id),
    FOREIGN KEY (document_id) REFERENCES Documents(id)
);