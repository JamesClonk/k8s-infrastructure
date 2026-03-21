#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [cert-manager] ..."
ytt --ignore-unknown-comments -f templates |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a cert-manager -c -y -f -
kapp app-change garbage-collect -a cert-manager --max 5 -y
