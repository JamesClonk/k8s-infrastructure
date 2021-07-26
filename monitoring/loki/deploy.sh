#!/bin/bash
set -e
set -u
source ../../setup.sh

# deploy
echo "deploying [loki] ..."
sops -d ../../secrets.sops |
	ytt --ignore-unknown-comments -f templates -f ../values.yml -f ../../configuration.yml -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a loki -c -y -f -
kapp app-change garbage-collect -a loki --max 5 -y
