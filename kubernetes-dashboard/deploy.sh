#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [kubernetes-dashboard] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - --data-value-file dashboard.kubeconfig="${KUBECONFIG}" |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kubernetes-dashboard -c -y -f -
kapp app-change garbage-collect -a kubernetes-dashboard --max 5 -y
