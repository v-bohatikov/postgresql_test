-- Create a procedure for generation of new partiotions
create or replace procedure create_monthly_partitions_for_range(
    p_start_date   date,
    p_end_date     date
)
language plpgsql as
$$
    declare
        month_start     date;
        month_end       date;
        partition_name  text;
        sql             text;
    begin
        if p_start_date is null or p_end_date is null then
            raise exception 'p_start_date and p_end_date must not be null';
        end if;

        if p_start_date > p_end_date then
            raise exception 'p_start_date (%) must be <= p_end_date (%)', p_start_date, p_end_date;
        end if;

        -- Include the month containing p_start_date
        month_start := date_trunc('month', p_start_date)::date;

        -- Include the month containing p_end_date
        -- NOTE: required for the case when the date present the first day of the month
        month_end := (date_trunc('month', p_end_date)::date + interval '1 month')::date;

        while month_start < month_end loop
            partition_name := format(
                '%operation_y%sm%s',
                to_char(month_start, 'YYYY'),
                to_char(month_start, 'MM')
            );

            -- Checking whether this partition exists or not
            perform 1
            from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
            where c.relname = partition_name and n.nspname = current_schema();

            if not found then
                -- Create new partiotion that will include range of dates [01/{month} - 01/{month + 1})
                sql := format(
                    'create table %I partition of %I for values from (%L) to (%L);',
                    partition_name,
                    operation,
                    month_start,
                    (month_start + interval '1 month')::date
                );

                execute sql;
                raise notice 'partition % created', partition_name;
            end if;

            month_start := (month_start + interval '1 month')::date;
        end loop;
    end;
$$;

-- Configure a scheduled task that will create new partitions automatically
SELECT cron.schedule(
    'create_next_month_partition',
    '0 1 * * *',    -- Runs everyday at 01:00
    $$
        call create_monthly_partitions(
            (current_date - interval '3 months')::date,
            current_date
        );
    $$
);
