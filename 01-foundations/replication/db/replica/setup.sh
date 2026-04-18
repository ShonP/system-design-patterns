#!/bin/bash
# Entrypoint for the replica container.
#
# On first boot the replica's data directory is empty. We:
#   1) wait until the primary accepts connections
#   2) run pg_basebackup to clone the primary's data directory, including a
#      standby.signal file (-R) and using our replication slot (-S)
#   3) hand off to the normal postgres docker entrypoint so postgres starts
#      up in hot-standby (read-only) mode and streams WAL from the primary
#
# On subsequent boots PGDATA is already populated, so we skip straight to
# starting postgres.
set -e

echo "[replica] waiting for primary..."
until PGPASSWORD=replicator pg_isready -h primary -p 5432 -U replicator; do
    sleep 1
done

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[replica] PGDATA empty -> running pg_basebackup from primary"
    PGPASSWORD=replicator pg_basebackup \
        -h primary -p 5432 -U replicator \
        -D "$PGDATA" \
        -Fp -Xs -R -S replica_slot -w
    chmod 0700 "$PGDATA"
    echo "[replica] base backup complete, standby.signal in place"
fi

exec docker-entrypoint.sh postgres -c hot_standby=on
