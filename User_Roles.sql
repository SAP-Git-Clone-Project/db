USE my_app_db;
CREATE TABLE IF NOT EXISTS User_Roles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT,
    FOREIGN KEY (user_id) REFERENCES User(id),
    FOREIGN KEY (role_id) REFERENCES Roles(id),
    FOREIGN KEY (assigned_by) REFERENCES User(id)
);