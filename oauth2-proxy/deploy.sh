#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [oauth2-proxy] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a oauth2-proxy -c -y -f -
kapp app-change garbage-collect -a oauth2-proxy --max 5 -y
