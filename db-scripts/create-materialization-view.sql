-- Create a materialization view with support of increment update on changes of 'state' column
SELECT pgivm.create_immv(
  'mv_operations_by_client_id_sum_aggregate',
  $$
    SELECT
        client_id,
        is_online_op,
        SUM(op_sum) AS total_sum
    FROM operation
    WHERE op_state = true
    GROUP BY client_id, is_online_op
  $$
);

create unique index mv_operations_by_client_id_sum_aggregate_pk
on mv_operations_by_client_id_sum_aggregate (client_id, is_online_op);