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

-- Create a function for generation of row
create or replace function generate_operation_row(
    start_date date,
    end_date   date,
    -- Used to forces per-row correlation and garanties execution of function per row
    _seed      int
)
returns table (
    op_date    date,
    op_state   boolean,
    op_sum     numeric(19,4),
    op_details jsonb
)
language plpgsql as
$$
    declare
        new_date    date;
    begin
        -- op_date: random date in specyfied range [start_date, end_date]
        --   - when end_date is null that means that we need to use a specific date passed in start_date
        -- NOTE: date + int is valid, PosgreSQL identifies int result as amount of days
        if end_date is null then
            new_date := start_date;
        else
            new_date := start_date + floor(random() * (end_date - start_date + 1))::int;
        end if;

        return query
        select
            new_date,
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
        from client c
        offset floor(random() * (select count(*) from client))
        limit 1;
    end;
$$;

-- Create a procedure for generation of 100_000 rows in a range of last 3-4 month
create or replace procedure generate_operations()
language plpgsql as
$$
    declare
        start_date      date := (current_date - interval '3 months')::date;
        end_date        date := current_date;
        row_amount      int := 100000;
        batch_size      int := 5000;
        remaining       integer := row_amount;
        current_batch   int;
    begin        
        -- Create partiotions required for this range
        call create_monthly_partitions_for_range(
            start_date,
            end_date
        );

        -- Generate rows in batches
        -- NOTE: That should minimize WAL pressure and make it easier for our materialization view to process data
        while remaining > 0 loop
            current_batch := least(batch_size, remaining);

            -- Generate a batch of rows
            insert into operation (
                op_date,
                op_state,
                op_sum,
                op_details
            )
            select
                r.op_date,
                r.op_state,
                r.op_sum,
                r.op_details
            from generate_series(1, current_batch) as gs(i)
            -- Used to execute this part once per left-hand row(generated one)
            cross join lateral generate_operation_row(start_date, end_date, gs.i) as r;
            commit; 

            remaining := remaining - current_batch;
        end loop;
    end;
$$;