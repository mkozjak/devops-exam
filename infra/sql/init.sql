CREATE DATABASE IF NOT EXISTS devops;
USE devops;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL
);

ALTER TABLE users ADD CONSTRAINT uniq UNIQUE(name, email);

-- Create 'app' user and grant privileges to 'devops' database
CREATE USER 'app'@'%' IDENTIFIED BY 'shouldBeChanged';
GRANT ALL PRIVILEGES ON devops.* TO 'app'@'%';
FLUSH PRIVILEGES;