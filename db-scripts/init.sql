-- Configure required elements
\i 1-create-tables.sql
\i 2-configure-continues-patitioning-support.sql
\i 3-create-materialization-view.sql
\i 4-configure-sheduled-data-mutations.sql
\i 5-create-data-generation-procedures.sql

-- Generate the data
\i generate-data.sql