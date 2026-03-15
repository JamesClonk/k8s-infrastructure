#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# vars
export S3_ACCESS_KEY="{{{ .postgres.backup.s3.access_key_id }}}"
export S3_SECRET_KEY="{{{ .postgres.backup.s3.secret_access_key }}}"
export S3_ENDPOINT="{{{ .postgres.backup.s3.endpoint }}}"
export S3_BUCKET="{{{ .postgres.backup.s3.bucket }}}"

# download
set +x
mc alias set postgres_backup "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}" --api S3v2
echo "downloading latest backup of [postgres] from [${S3_ENDPOINT}/${S3_BUCKET}] to [postgres_backup.sql] ..."
mc ls postgres_backup/${S3_BUCKET}/pgbackup/
mc ls --json postgres_backup/${S3_BUCKET}/pgbackup/ | jq -r -s 'sort_by(.lastModified) | last | .key' | xargs -I{} mc cp postgres_backup/${S3_BUCKET}/pgbackup/{} postgres_backup.sql.gz
#gzip -d postgres_backup.sql.gz
