#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [cert-manager] ..."
cat values.yml |
	envsubst -no-unset -no-empty |
	ytt --ignore-unknown-comments -f templates -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a cert-manager -c -y -f -
kapp app-change garbage-collect -a cert-manager --max 5 -y
