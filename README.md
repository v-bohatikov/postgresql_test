# PostgreSQL Test Assignment – Partitioning, Scheduling, Aggregation, and Replication

## Overview

This repository contains an implementation of a PostgreSQL-based system designed to simulate a transactional workload with frequent inserts and updates, while maintaining real-time aggregated financial data and replicating transactional data to a secondary instance.

The solution demonstrates:

- Time-based partitioning
- High-volume data generation
- Scheduled inserts and updates
- Incremental materialized view maintenance
- Logical replication
- Observability tooling

The implementation favors correctness, predictability, and operational clarity over premature optimization.

---

## Task Description

The goal of this task is to design and implement a PostgreSQL solution that fulfills the following requirements:

1. Create a **partitioned table `T1`** with the following fields:
   - `date`
   - `id`
   - `amount`
   - `state`
   - `transaction_guid`
   - `message` (JSONB), containing:
     - account number
     - client ID
     - operation type (`online` or `offline`)

2. Generate data for table `T1` using a stored procedure or function:
   - At least **100,000 rows**
   - Covering **3–4 months** of data

3. Ensure **uniqueness** of the `transaction_guid` field.

4. Create a **scheduled task** that inserts a new record into `T1` **every 5 seconds** with `state = 0`.

5. Create a **scheduled task** that updates the `state` field from `0` to `1` **every 3 seconds**:
   - If the current second is even → update rows with even `id`
   - If the current second is odd → update rows with odd `id`

6. Maintain the **current total amount** grouped by:
   - `client_id`
   - `operation_type`

   This must be stored in a **materialized view**, updated whenever `state` changes from `0` to `1`.

7. Configure **replication** of table `T1` to a second PostgreSQL instance.

---

## Deliverables

This repository provides:

- Infrastructure definition using Docker
- Database schema, functions, and scheduled jobs
- Incremental materialized view logic
- Logical replication configuration
- Observability tooling (PMM, pgAdmin)
- Utility scripts for lifecycle management

---

## Requirements

### Mandatory

- **Docker**
- **Authenticated Docker environment**  
  Authentication is required to pull some of the container images.

### Operating System

- Scripts are written for **Windows**
- Running on Windows is a *soft requirement*
- On non-Windows systems, equivalent commands must be executed manually based on script contents

### Provided Scripts

| Script | Description |
|------|------------|
| `start_infra.bat` | Start all Docker services |
| `stop_infra.bat` | Stop all Docker services |
| `init_db.bat` | Initialize database schema and logic |
| `cleanup_db.bat` | Remove database objects and data |

---

## Local Deployment

### 1. Start Infrastructure

```bat
start_infra.bat
```

This will start:
- Primary PostgreSQL instance
- Replica PostgreSQL instance
- PMM Server
- pgAdmin

---

### 2. Initialize Database

```bat
init_db.bat
```

This step:
- Creates schemas, tables, partitions
- Generates base data
- Configures `pg_cron` jobs
- Sets up replication
- Creates materialized views

---

### 3. Stop Infrastructure (Optional)

```bat
stop_infra.bat
```

---

### 4. Cleanup (Optional)

```bat
cleanup_db.bat
```

---

## How to Use

Once initialized:

- Data will be inserted automatically every **5 seconds**
- State transitions will occur every **3 seconds**
- Aggregated totals will update incrementally
- Replication will stream changes to the replica instance
- Metrics and queries can be observed via PMM

---

## Design Decisions and Notes

### Partitioning Strategy

- **Range partitioning by date**
- **One partition per month**
- Base partitions are created during initial data generation
- A dedicated script creates the next month’s partition at the beginning of each month

---

### JSONB Handling: Generated Columns vs Expression Indexes

Expression indexes on JSONB fields were considered but ultimately rejected in favor of **generated columns**.

Key reasons:
- Reduced trigger overhead
- More reliable optimizer behavior
- Efficient IMMV maintenance
- Cleaner view definitions

**Conclusion:**  
Generated columns provide predictable and performant integration with `pg_ivm`.

---

### Incremental Materialized Views (`pg_ivm`)

- Used for maintaining aggregated totals incrementally
- Partitioned tables are unsupported, so a projection table is used

---

### Scheduling (`pg_cron`)

- Used for all scheduled tasks
- Simulates load with short intervals and internal loops

---

### Replication

- Logical replication configured between two instances
- Supports failover configuration (not implemented)

#### Archivation

- WAL archiving enabled as a best practice

---

## Observability Tools

### PMM

- **Do NOT change the default password on first login**
- Enable **Query Analytics (QAN)** in Settings → Advanced Settings
- Restart infrastructure after enabling QAN

---

### pgAdmin

- Preconfigured
- Displays both PostgreSQL instances

---

## Scope Limitations

- No automated failover
- No enforcement of date immutability
- Focus on correctness and maintainability
