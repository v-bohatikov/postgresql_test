-- Configure tables
\ir config-scripts/1-create-tables.sql
\ir config-scripts/2-configure-continues-patitioning-support.sql
\ir config-scripts/3-create-data-generation-procedures.sql

-- Generate defaule data before further configuration
\ir data-manipulation/generate-data.sql

-- Configure MV and data mutation tasks
\ir config-scripts/4-create-materialization-view-support.sql
\ir config-scripts/5-configure-sheduled-data-mutations.sql

