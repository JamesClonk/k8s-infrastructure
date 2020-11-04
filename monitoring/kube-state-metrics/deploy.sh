#!/bin/bash
set -e
set -u
source ../../setup.sh

# deploy
echo "deploying [kube-state-metrics] ..."
ytt --ignore-unknown-comments -f templates -f values.yml |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kube-state-metrics -c -y -f -
kapp app-change garbage-collect -a kube-state-metrics --max 5 -y
