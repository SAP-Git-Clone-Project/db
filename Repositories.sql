CREATE TABLE Repositories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_private BOOLEAN DEFAULT FALSE,
    default_branch VARCHAR(50) DEFAULT 'main',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    UNIQUE (owner_id, name),
    -- A user cannot have two repos with the same name 
    FOREIGN KEY (owner_id) REFERENCES Users(id) ON DELETE CASCADE
    -- The owner must exist in the users table
);
