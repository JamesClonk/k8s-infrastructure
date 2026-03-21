#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# create new backup
echo "creating backup [postgres_backup.sql] from [postgres] database ..."
kubectl exec -i -n postgres postgres-0 -- env PGPASSWORD="{{{ .postgres.password }}}" pg_dumpall -U postgres -h 127.0.0.1 -p 6432 --no-password --clean > postgres_backup.sql
