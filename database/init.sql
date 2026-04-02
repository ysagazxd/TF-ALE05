CREATE DATABASE IF NOT EXISTS monitoring;
USE monitoring;

CREATE TABLE IF NOT EXISTS service_metrics (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    service     VARCHAR(50) NOT NULL,
    status      ENUM('healthy','warning','critical','unknown') NOT NULL,
    response_time INT,
    uptime      DECIMAL(5,2),
    extra_data  JSON,
    checked_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_service_time (service, checked_at)
);

CREATE TABLE IF NOT EXISTS alerts (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    service     VARCHAR(50) NOT NULL,
    message     TEXT NOT NULL,
    severity    ENUM('info','warning','critical') NOT NULL,
    resolved    BOOLEAN DEFAULT FALSE,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created (created_at)
);

CREATE TABLE IF NOT EXISTS health_history (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    service     VARCHAR(50) NOT NULL,
    date        DATE NOT NULL,
    uptime_pct  DECIMAL(5,2),
    avg_response_time INT,
    total_checks INT DEFAULT 0,
    failed_checks INT DEFAULT 0,
    UNIQUE KEY uq_service_date (service, date)
);
