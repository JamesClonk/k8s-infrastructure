#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [cert-manager] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a cert-manager -c -y -f -
kapp app-change garbage-collect -a cert-manager --max 5 -y
