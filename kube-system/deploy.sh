#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [kube-system] ..."
ytt --ignore-unknown-comments -f templates -f values.yml |
	kapp deploy -a kube-system -c -y -f -
kapp app-change garbage-collect -a kube-system --max 5 -y
