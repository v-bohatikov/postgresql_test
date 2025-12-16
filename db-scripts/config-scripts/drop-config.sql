-- 1. Remove cron jobs
SELECT cron.unschedule('create_next_month_partition_task');
SELECT cron.unschedule('generate_new_operation_task');
SELECT cron.unschedule('change_operation_state_task');

-- 2. Drop procedures and functions
DROP PROCEDURE IF EXISTS create_monthly_partitions_for_range(date, date);
DROP PROCEDURE IF EXISTS generate_operation_every_5_seconds();
DROP PROCEDURE IF EXISTS change_operation_state_every_3_seconds();
DROP PROCEDURE IF EXISTS generate_clients();
DROP FUNCTION IF EXISTS generate_row(date, date);
DROP PROCEDURE IF EXISTS generate_operations();

-- 3. Drop incremental materialized view
DROP MATERIALIZED VIEW IF EXISTS mv_operations_by_client_id_sum_aggregate;

-- 4. Drop tables
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS operation;