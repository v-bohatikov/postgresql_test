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