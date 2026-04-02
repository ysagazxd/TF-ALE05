-- Migration: 001_add_indexes.sql
USE monitoring;

ALTER TABLE service_metrics ADD INDEX IF NOT EXISTS idx_status (status);
ALTER TABLE alerts ADD INDEX IF NOT EXISTS idx_severity (severity);
