#!/bin/bash
set -e

# Create a replication user that the replica will use to stream WAL
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_pass';
    SELECT pg_create_physical_replication_slot('replica_slot');
EOSQL

# Allow the replication user to connect from any host
echo "host replication replicator all md5" >> "$PGDATA/pg_hba.conf"
