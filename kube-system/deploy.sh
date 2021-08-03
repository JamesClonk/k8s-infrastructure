#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [kube-system] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kapp deploy -a kube-system -c -y -f -
kapp app-change garbage-collect -a kube-system --max 5 -y
