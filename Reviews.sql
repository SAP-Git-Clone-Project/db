CREATE TABLE Reviews (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    version_id BIGINT NOT NULL,
    reviewer_id BIGINT NOT NULL,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    outcome ENUM('approved', 'rejected', 'changes_requested') NOT NULL,
    review_notes TEXT,
    FOREIGN KEY (version_id) REFERENCES Versions(id),
    FOREIGN KEY (reviewer_id) REFERENCES User(id)
);