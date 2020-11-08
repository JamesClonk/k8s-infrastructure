#!/bin/bash
set -e
set -u
source ../../setup.sh

# deploy
echo "deploying [grafana] ..."
cat ../values.yml |
	envsubst -no-unset -no-empty |
	ytt --ignore-unknown-comments -f templates -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a grafana -c -y -f -
kapp app-change garbage-collect -a grafana --max 5 -y
