#!/bin/bash
# =============================================================================
# Standby Server Entrypoint
# =============================================================================
# This script replaces the default PostgreSQL entrypoint for the standby.
# Instead of initializing a new database, it clones data from the primary
# using pg_basebackup, then starts PostgreSQL in hot standby mode.
#
# Hot standby = the server accepts read-only queries while replicating.
# =============================================================================
set -e

PGDATA="/var/lib/postgresql/data"

# Only do the base backup if this is a fresh container (no existing data)
if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "============================================"
    echo "Standby: No data found. Cloning from primary..."
    echo "============================================"

    # pg_basebackup copies the entire database from the primary
    # -h pg-primary   : connect to the primary container
    # -U replicator   : use the replication user
    # -D $PGDATA      : write data to this directory
    # -Fp              : plain format (not tar)
    # -Xs              : stream WAL during backup (most reliable)
    # -P               : show progress
    # -R               : create standby.signal + write primary_conninfo
    #                    (this tells PostgreSQL "you are a standby")
    pg_basebackup \
        -h pg-primary \
        -p 5432 \
        -U replicator \
        -D "$PGDATA" \
        -Fp -Xs -P -R \
        -S standby_slot

    # Append replication slot config so WAL records are not discarded
    echo "primary_slot_name = 'standby_slot'" >> "$PGDATA/postgresql.auto.conf"

    echo "============================================"
    echo "Standby: Base backup complete!"
    echo "============================================"
else
    echo "Standby: Existing data found. Resuming replication..."
fi

# Fix permissions (PostgreSQL requires 700 on data directory)
chmod 700 "$PGDATA"

# Start PostgreSQL — it will automatically enter standby mode
# because standby.signal exists in the data directory
exec postgres
