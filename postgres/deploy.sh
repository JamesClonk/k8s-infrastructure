#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [postgres] ..."
sops -d ../secrets.sops |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ../configuration.yml -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a postgres -c -y -f -
kapp app-change garbage-collect -a postgres --max 5 -y
