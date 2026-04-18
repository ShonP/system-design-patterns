#!/bin/bash
# Allow the replica to connect for streaming replication
echo "host replication replicator all md5" >> "$PGDATA/pg_hba.conf"
