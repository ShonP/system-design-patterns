#!/bin/bash
# This script initializes the replica from the primary using pg_basebackup,
# then starts PostgreSQL in standby (read-only) mode.

set -e

PGDATA="/var/lib/postgresql/data"

# If data directory is empty, bootstrap from primary
if [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
    echo "🔄 Bootstrapping replica from primary..."

    # Wait for primary to be fully ready
    until PGPASSWORD=replicator pg_isready -h postgres-primary -p 5432 -U replicator; do
        echo "   Waiting for primary..."
        sleep 2
    done

    # Copy data from primary
    PGPASSWORD=replicator pg_basebackup \
        -h postgres-primary \
        -p 5432 \
        -U replicator \
        -D "$PGDATA" \
        -Fp -Xs -R

    echo "✅ Base backup complete"

    # Configure the replica to use the replication slot
    cat >> "$PGDATA/postgresql.auto.conf" <<EOF
primary_conninfo = 'host=postgres-primary port=5432 user=replicator password=replicator'
primary_slot_name = 'replica_slot_1'
hot_standby = on
EOF

    # Signal that this is a standby
    touch "$PGDATA/standby.signal"
fi

echo "🚀 Starting replica..."
exec postgres
