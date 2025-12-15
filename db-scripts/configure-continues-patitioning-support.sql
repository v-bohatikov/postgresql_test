-- Create a procedure for generation of new partiotions
create or replace procedure create_next_month_partition()
language plpgsql
as $$
    declare
        next_start          date := (date_trunc('month', now()) + interval '1 month')::date;
        next_end            date := (date_trunc('month', now()) + interval '2 months')::date;
        parent_table_name   text := 'operation';
        partition_name      text := format(
                                        'operation_y%sm%s',
                                        to_char(next_start, 'YYYY'),
                                        to_char(next_start, 'MM')
                                    );
        sql                 text;
    begin
        -- Checking whether the partition table already exists or not
        perform 1
        from pg_class
        where relname = partition_name and n.nspname = current_schema();;

        if not found then
            sql := format(
                'create table %I partition of %I for values from (%L) to (%L);',
                partition_name,
                parent_table_name,
                next_start,
                next_end
            );

            execute sql;

            raise notice 'partition % created', partition_name;
        end if;
    end;
$$;


-- Configure a scheduled task that will create new partitions automatically
SELECT cron.schedule(
    'create_next_month_partition',
    '0 1 * * *',    -- Runs everyday at 01:00
    $$
        BEGIN;
        CALL create_next_month_partition();
        COMMIT;
    $$
);
