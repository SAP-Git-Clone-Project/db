CREATE TABLE Audit_Log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NULL, -- Changed to NULL to allow keeping logs of deleted users
    action_type ENUM(
        'create document', 
        'create version', 
        'delete document', 
        'export (pdf, txt. etc)', 
        'login', 
        'logout', 
        'approve version', 
        'reject version', 
        'update metadata'
    ) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE SET NULL
);