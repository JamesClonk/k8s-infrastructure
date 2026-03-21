#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# run backup job immediately
echo "running backup job based on cronjob ..."
kubectl create job --from=cronjob/pgbackup manual-backup -n postgres
