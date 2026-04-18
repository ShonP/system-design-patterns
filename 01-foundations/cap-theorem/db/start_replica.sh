#!/bin/bash
# This script initializes the replica from the primary using pg_basebackup,
# then starts PostgreSQL in standby (read-only) mode.

set -e

PGDATA="/var/lib/postgresql/data"

# Make sure the data directory is owned by the postgres user (we run as root
# initially because the entrypoint is /bin/bash, but PostgreSQL itself must
# run as an unprivileged user).
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"
chmod 0700 "$PGDATA"

# If data directory is empty, bootstrap from primary
if [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
    echo "🔄 Bootstrapping replica from primary..."

    # Wait for primary to be fully ready (run as postgres so pg_isready uses
    # the right defaults; the host/port flags make this independent of the user)
    until gosu postgres bash -c "PGPASSWORD=replicator pg_isready -h postgres-primary -p 5432 -U replicator"; do
        echo "   Waiting for primary..."
        sleep 2
    done

    # Copy data from primary as the postgres user so file ownership is correct
    gosu postgres bash -c "PGPASSWORD=replicator pg_basebackup \
        -h postgres-primary \
        -p 5432 \
        -U replicator \
        -D '$PGDATA' \
        -Fp -Xs -R"

    echo "✅ Base backup complete"

    # Configure the replica to use the replication slot
    gosu postgres bash -c "cat >> '$PGDATA/postgresql.auto.conf'" <<EOF
primary_conninfo = 'host=postgres-primary port=5432 user=replicator password=replicator'
primary_slot_name = 'replica_slot_1'
hot_standby = on
EOF

    # Signal that this is a standby
    gosu postgres touch "$PGDATA/standby.signal"
fi

echo "🚀 Starting replica..."
# PostgreSQL refuses to run as root for security reasons, so drop privileges.
exec gosu postgres postgres
