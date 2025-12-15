-- Create a procedure for generation of default 100 users for next step of data generation
create or replace procedure generate_clients()
language plpgsql as
$$
    begin
        insert into client
        select
        from generate_series(1, 100);
    end;
$$;

-- Create a procedure for generation of 100_000 rows in a range of last 4 month
create or replace procedure generate_operations()
language plpgsql as
$$
    declare
        row_amount  int := 100000
        start_date  date := (current_date - interval '3 months')::date;
        end_date    date := current_date;
    begin
        -- Create partiotions required for this range
        call create_monthly_partitions(
            start_date,
            end_date
        );

        insert into operation (
            op_date,
            op_state,
            op_sum,
            op_details
        )
        select
            -- op_date: random date in [current_date - 3 months, current_date]
            -- NOTE: date + int is valid, PosgreSQL identifies int result as amount of days
            start_date + floor(random() * (end_date - start_date + 1))::int,

            -- op_state: always false
            false,

            -- op_sum: random amount between 0.01 and 10000.0000
            round((random() * 9999.99 + 0.01)::numeric, 4),

            -- op_details:
            --  - client_id:                client.id
            --  - client_account_number:    client.account_number
            --  - is_online_op:             rundom value from 0 to 1
            jsonb_build_object(
                'client_id', c.id,
                'client_account_number', c.account_number,
                'is_online_op', (random() < 0.5)
            )
        from generate_series(1, row_amount) gs_tmp
        -- Used to execute this part once per left-hand row(generated one)
        cross join lateral (
            select id, account_number
            from client
            offset floor(random() * (select count(*) from client)) -- Should minimize WAL overhead
            limit 1
        ) c
    end;
$$;