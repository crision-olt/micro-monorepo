-- Initial PostgreSQL setup
-- This script runs once when the container is first created.
-- Add shared schemas, extensions, or seed data here.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Per-app schemas — avoids table name collisions between services
CREATE SCHEMA IF NOT EXISTS heimdall;
CREATE SCHEMA IF NOT EXISTS references_api;
