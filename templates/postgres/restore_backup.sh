#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# import
echo "import backup from [postgres_backup.sql] into [postgres] database ..."
#kubectl exec -i -n postgres postgres-0 -- env PGPASSWORD="{{{ .postgres.password }}}" psql -U postgres -h 127.0.0.1 -p 6432 < postgres_backup.sql
gunzip -c postgres_backup.sql.gz | kubectl exec -i -n postgres postgres-0 -- env PGPASSWORD="{{{ .postgres.password }}}" psql -U postgres -h 127.0.0.1 -p 6432
