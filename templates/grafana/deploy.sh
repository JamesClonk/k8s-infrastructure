#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [grafana] ..."
build/render.sh
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f - |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a grafana -c -y -f -
kapp app-change garbage-collect -a grafana --max 5 -y
