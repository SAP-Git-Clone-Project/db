CREATE TABLE Audit_Log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
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
    FOREIGN KEY (user_id) REFERENCES User(id)
);