#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [kubernetes-dashboard] ..."
INGRESS_BASIC_AUTH=$(basic_auth "${INGRESS_BASIC_AUTH_USERNAME}" "${INGRESS_BASIC_AUTH_PASSWORD}")
cat values.yml |
	envsubst -no-unset -no-empty |
	ytt --ignore-unknown-comments -f templates -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kubernetes-dashboard -c -y -f -
kapp app-change garbage-collect -a kubernetes-dashboard --max 5 -y
