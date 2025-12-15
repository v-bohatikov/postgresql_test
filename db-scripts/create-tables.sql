-- Create a support table with unique users for simplification of future data generation
create table client(
    id              bigint          generated always as identity primary key,
    account_number  uuid            unique not null default uuidv7(),
)

-- Create a main table for operations
create table operation (
    id              bigint          generated always as identity primary key,
    op_uuid         uuid            unique not null default uuidv7(),
    op_date         date            not null,
    op_state        boolean         not null,
    op_sum          numeric(19, 4)  not null,
    -- Contains 'client_id(bigint), client_account_number(uuid), is_online_op(boolean)'
    op_details      jsonb           not null,
    client_id       bigint          GENERATED ALWAYS AS ((op_details->>'client_id')::bigint) STORED
    is_online_op    boolean         GENERATED ALWAYS AS ((op_details->>'is_online_op')::boolean) STORED
) partition by range (op_date);

create index idx_operation_partiotion_support
on operation (op_date);

create index idx_operation_unfinished_id_parity
on operation ((id % 2))
where op_state = false;

create index idx_operation_mv_support
on operation (client_id, is_online_op)
include (op_sum) -- Should make it available without heap access
where op_state = true;

-- Create 4 default partitions for data generation
create table operation_y2025m09 partition of operation
-- NOTE: Adjacent partitions can share a bound value, since range upper bounds are treated as exclusive bounds.
for values from ('2025-09-01') to ('2026-10-01');

create table operation_y2025m10 partition of operation
for values from ('2025-10-01') to ('2026-11-01');

create table operation_y2025m11 partition of operation
for values from ('2025-11-01') to ('2026-12-01');

create table operation_y2025m12 partition of operation
for values from ('2025-12-01') to ('2026-01-01');