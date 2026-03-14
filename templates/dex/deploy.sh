#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [dex] ..."
build/render.sh
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a dex -c -y -f -
kapp app-change garbage-collect -a dex --max 5 -y
