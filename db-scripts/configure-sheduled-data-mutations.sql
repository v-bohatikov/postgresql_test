-- Create a scheduled task for adding a new row of data every 5 seconds

-- NOTE: I assume that idea is to simulate load and not whether I can create a
-- code that will be executed in small intervals. So I have decided to use the
-- simple approach using 'cron' with inner loop with sleep instraction to simulate
-- required bechavior.
create or replace procedure generate_operation_every_5_seconds()
language plpgsql as
$$
    declare
        i integer;
    begin
        -- Using lock to prevent overlapping executions
        if not pg_try_advisory_lock(424242) then
            return;
        end if;

        begin
            for i in 1..12 loop
                insert into operation (
                    op_date,
                    op_state,
                    op_sum,
                    op_details
                )
                select *
                from generate_operation_row(current_date, null);

                -- Sleep only between iterations to prevent lock collisions
                if i < 12 then
                    perform pg_sleep(5);
                end if;
            end loop;
        
            -- Normal unlock
            perform pg_advisory_unlock(424242);

        exception
            when others then
                -- Ensure unlock on error
                perform pg_advisory_unlock(424242);
                raise;
        end;
    end;
$$;

SELECT cron.schedule(
    'generate_new_operation_task',
    -- Runs every minute, further granulation done inside
    '* * * * *',
    $$call generate_operation_every_5_seconds();$$
);

-- Create a scheduled task for updating a 'state' column every 3 seconds
-- - update rows with even ids when amount of seconds is even
-- - update rows with odd ids otherwise

-- NOTE: I assume that the idea is to simulate load and not whether I can create a
-- code that will be executed in small intervals. So I have decided to use the
-- simple approach using 'cron' with inner loop with sleep instraction to simulate
-- required bechavior.
create or replace procedure change_operation_state_every_3_seconds()
language plpgsql as
$$
    declare
        i               int;
        remainder       int;
        rows_updated    int;
    begin
        -- Using lock to prevent overlapping executions
        if not pg_try_advisory_lock(434343) then
            return;
        end if;

        begin
            for i in 1..20 loop            
                -- Determine remainder from modulus operator on passed seconds
                -- That will be used to determine whether we are going to update even or odd ids 
                remainder := 
                    case
                        when extract(second from now())::int % 2 = 0 then 0
                        else 1
                    end;
                
                -- Processing all matching rows in batches to minimize WAL pressure 
                loop
                    update operation
                    set op_state = true
                    where ctid in (
                        select ctid
                        from operation
                        where op_state = false and id % 2 = remainder
                        limit 1000
                    );

                    -- Exit inner loop when there no more matching rows
                    get diagnostics rows_updated = row_count;
                    exit when rows_updated = 0;
                end loop;

                -- Sleep only between iterations to prevent lock collisions
                if i < 20 then
                    perform pg_sleep(3);
                end if;
            end loop;

            -- Normal unlock
            perform pg_advisory_unlock(434343);

        exception
            when others then
                -- Ensure unlock on error
                perform pg_advisory_unlock(434343);
                raise;
        end;
    end;
$$;

SELECT cron.schedule(
    'change_operation_state_task',
    -- Runs every minute, further granulation done inside
    '* * * * *',
    $$call change_operation_state_every_3_seconds();$$
);