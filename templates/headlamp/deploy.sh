#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [headlamp] ..."
build/render.sh
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f - --data-value-file dashboard.kubeconfig="${KUBECONFIG}" |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a headlamp -c -y -f -
kapp app-change garbage-collect -a headlamp --max 5 -y
