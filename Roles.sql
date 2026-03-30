USE my_app_db;
CREATE TABLE IF NOT EXISTS Roles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_name ENUM('author', 'reviewer', 'reader', 'administrator') NOT NULL,
    description TEXT
);
