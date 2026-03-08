#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [headlamp] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a headlamp -c -y -f -
kapp app-change garbage-collect -a headlamp --max 5 -y
