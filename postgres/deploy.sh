#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [postgres] ..."
cat values.yml |
	envsubst -no-unset -no-empty |
	ytt --ignore-unknown-comments -f templates -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a postgres -c -y -f -
kapp app-change garbage-collect -a postgres --max 5 -y
