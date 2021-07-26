#!/bin/bash
set -e
set -u
source ../../setup.sh

# deploy
echo "deploying [kube-state-metrics] ..."
sops -d ../../secrets.sops |
	ytt --ignore-unknown-comments -f templates -f ../values.yml -f ../../configuration.yml -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kube-state-metrics -c -y -f -
kapp app-change garbage-collect -a kube-state-metrics --max 5 -y
