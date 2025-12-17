-- Create a trigger for adding completed operations into projection table
create function project_completed_operation()
returns trigger
language plpgsql as
$$
  begin
      insert into completed_operation_projection (
          op_id,
          op_date,
          client_id,
          is_online_op,
          op_sum
      )
      values (
          new.id,
          new.op_date,
          new.client_id,
          new.is_online_op,
          new.op_sum
      )
      on conflict (op_id, op_date) do nothing;

      return new;
end;
$$;

create trigger trg_project_completed_operation
after update of op_state on operation
for each row
when (old.op_state = false and new.op_state = true)
execute function project_completed_operation();

-- Create a materialization view with support of increment update on changes of 'state' column
SELECT pgivm.create_immv(
  'mv_operations_by_client_id_sum_aggregate',
  $$
    SELECT
        client_id,
        is_online_op,
        SUM(op_sum) AS total_sum
    FROM completed_operation_projection
    GROUP BY client_id, is_online_op
  $$
);

create unique index if not exists mv_operations_by_client_id_sum_aggregate_pk
on mv_operations_by_client_id_sum_aggregate (client_id, is_online_op);