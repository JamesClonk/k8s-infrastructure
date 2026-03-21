#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [loki] ..."
build/render.sh
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f - |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a loki -c -y -f -
kapp app-change garbage-collect -a loki --max 5 -y
