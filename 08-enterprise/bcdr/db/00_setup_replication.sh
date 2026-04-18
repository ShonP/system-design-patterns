#!/bin/bash
# =============================================================================
# Setup Replication on the Primary
# =============================================================================
# This script runs automatically when the primary PostgreSQL container starts
# for the first time. It creates a replication user and a replication slot
# that the standby server will use to stream WAL (Write-Ahead Log) records.
# =============================================================================
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create a user specifically for replication (limited permissions)
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator';

    -- Create a replication slot so WAL records are retained for the standby
    -- even if the standby is temporarily disconnected
    SELECT pg_create_physical_replication_slot('standby_slot');
EOSQL

# Allow the replicator user to connect for replication from any host
echo "host replication replicator 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

# Reload PostgreSQL to pick up the new pg_hba.conf entry
pg_ctl reload -D "$PGDATA"

echo "=== Replication setup complete on primary ==="
