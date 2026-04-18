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

  # The data directory must be owned by the postgres user and have 0700
  # permissions, otherwise PostgreSQL refuses to start.
  chown -R postgres:postgres /var/lib/postgresql/data
  chmod 0700 /var/lib/postgresql/data
  echo "✅ Base backup complete. Starting replica..."
fi

# PostgreSQL refuses to run as root, so we drop to the postgres user.
# `gosu` is shipped with the official postgres image for exactly this.
exec gosu postgres postgres -c hot_standby=on
