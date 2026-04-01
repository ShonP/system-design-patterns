#!/bin/bash
set -e

# Wait for the primary to be ready before attempting replication
until pg_isready -h postgres-primary -p 5432 -U replicator; do
  echo "⏳ Waiting for primary to be ready..."
  sleep 2
done

# If the data directory is empty, perform a base backup from primary.
# pg_basebackup copies the entire database cluster from the primary.
# The -R flag automatically creates standby.signal and sets primary_conninfo.
if [ ! -s "/var/lib/postgresql/data/PG_VERSION" ]; then
  echo "📦 Performing base backup from primary..."
  rm -rf /var/lib/postgresql/data/*

  PGPASSWORD=replicator_pass pg_basebackup \
    -h postgres-primary \
    -p 5432 \
    -U replicator \
    -D /var/lib/postgresql/data \
    -Fp -Xs -P -R \
    -S replica_slot

  # Ensure correct permissions
  chmod 0700 /var/lib/postgresql/data
  echo "✅ Base backup complete. Starting replica..."
fi

# Start PostgreSQL in standby (read-only) mode
exec postgres -c hot_standby=on
