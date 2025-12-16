-- Generate default 100 users for next step of data generation
call generate_clients();

-- Generate 100_000 rows in a range of last 4 month
call generate_operations();