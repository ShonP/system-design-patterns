#!/bin/bash
# This script runs once, the first time the primary Postgres container starts.
# It creates:
#   1) a dedicated "replicator" role the replica will use to pull WAL
#   2) a physical replication slot so the replica never misses WAL records
#   3) a demo table with some rows so the notebooks have something to read
#
# It also appends a pg_hba.conf rule so the replicator role is allowed to
# connect from other containers in the docker network.
set -e

echo "host replication replicator all md5" >> "$PGDATA/pg_hba.conf"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator';
    SELECT pg_create_physical_replication_slot('replica_slot');

    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        username    TEXT UNIQUE NOT NULL,
        email       TEXT NOT NULL,
        created_at  TIMESTAMPTZ DEFAULT NOW()
    );

    INSERT INTO users (username, email) VALUES
        ('alice',   'alice@example.com'),
        ('bob',     'bob@example.com'),
        ('charlie', 'charlie@example.com');
EOSQL
