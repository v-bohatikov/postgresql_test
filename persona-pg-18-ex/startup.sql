-- Create a user with permissions for monitoring for PMM
CREATE USER pmm WITH ENCRYPTED PASSWORD 'pmm_password';
GRANT pg_monitor TO pmm;
GRANT pg_read_all_stats TO pmm;

-- Create a user with permission for streaming replication
CREATE ROLE replicator WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'replicator_password';
GRANT CONNECT ON DATABASE postgres TO replicator;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_stat_monitor;
CREATE EXTENSION IF NOT EXISTS pg_ivm;