-- 1. Remove cron jobs
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname IN (
  'create_next_month_partition_task',
  'generate_new_operation_task',
  'change_operation_state_task'
);

-- 2. Remove triggers
DROP TRIGGER IF EXISTS trg_project_completed_operation ON operation;
DROP FUNCTION IF EXISTS project_completed_operation();

-- 3. Drop procedures and functions
DROP PROCEDURE IF EXISTS create_monthly_partitions_for_range(date, date);
DROP PROCEDURE IF EXISTS generate_operation_every_5_seconds();
DROP PROCEDURE IF EXISTS change_operation_state_every_3_seconds();
DROP PROCEDURE IF EXISTS generate_clients();
DROP FUNCTION IF EXISTS generate_row(date, date);
DROP PROCEDURE IF EXISTS generate_operations();

-- 4. Drop incremental materialized view
DROP MATERIALIZED VIEW IF EXISTS mv_operations_by_client_id_sum_aggregate;

-- 5. Drop tables
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS operation;
DROP TABLE IF EXISTS completed_operation_projection;