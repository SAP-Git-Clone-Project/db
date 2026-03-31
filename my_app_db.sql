USE my_app_db;

-- USERS
CREATE TABLE IF NOT EXISTS Users (
    id CHAR(36) PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ROLES
CREATE TABLE IF NOT EXISTS Roles (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36),
    role_name VARCHAR(50),
    description TEXT
);

-- USER_ROLES
CREATE TABLE IF NOT EXISTS User_Roles (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    role_id CHAR(36) NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by CHAR(36),
    UNIQUE (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES Roles(id) ON DELETE CASCADE
);

-- DOCUMENTS
CREATE TABLE IF NOT EXISTS Documents (
    id CHAR(36) PRIMARY KEY,
    created_by CHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (created_by) REFERENCES Users(id) ON DELETE CASCADE
);

-- DOCUMENT_PERMISSIONS
CREATE TABLE IF NOT EXISTS Document_Permissions (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    document_id CHAR(36) NOT NULL,
    permission_type INT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, document_id),
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE,
    FOREIGN KEY (document_id) REFERENCES Documents(id) ON DELETE CASCADE
);

-- VERSIONS
CREATE TABLE IF NOT EXISTS Versions (
    id CHAR(36) PRIMARY KEY,
    document_id CHAR(36) NOT NULL,
    version_number INT NOT NULL,
    content TEXT,
    status INT,
    parent_version_id CHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    file_path VARCHAR(255),
    file_size BIGINT,
    checksum VARCHAR(255),
    UNIQUE (document_id, version_number),
    FOREIGN KEY (document_id) REFERENCES Documents(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_version_id) REFERENCES Versions(id) ON DELETE SET NULL
);

-- REVIEWS
CREATE TABLE IF NOT EXISTS Reviews (
    id CHAR(36) PRIMARY KEY,
    version_id CHAR(36) NOT NULL,
    reviewer_id CHAR(36) NOT NULL,
    review_status INT NOT NULL,
    comments TEXT,
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES Versions(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES Users(id) ON DELETE CASCADE
);

-- AUDIT_LOG
CREATE TABLE IF NOT EXISTS Audit_log (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36),
    document_id CHAR(36),
    version_id CHAR(36),
    action_type INT NOT NULL,
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE SET NULL,
    FOREIGN KEY (document_id) REFERENCES Documents(id) ON DELETE SET NULL,
    FOREIGN KEY (version_id) REFERENCES Versions(id) ON DELETE SET NULL
);