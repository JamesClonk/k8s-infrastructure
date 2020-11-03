#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [ingress-nginx] ..."
ytt --ignore-unknown-comments -f templates -f values.yml |
	kbld -f - -f image.lock.yml |
	kapp deploy -a ingress-nginx -c -y -f -
kapp app-change garbage-collect -a ingress-nginx --max 5 -y
