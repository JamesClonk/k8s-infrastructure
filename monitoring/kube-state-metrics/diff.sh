#!/bin/bash
set -e
set -u
source ../../setup.sh

# diff
kapp app-change list -a kube-state-metrics
ytt --ignore-unknown-comments -f templates -f ../values.yml |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kube-state-metrics -c --diff-run -f -
