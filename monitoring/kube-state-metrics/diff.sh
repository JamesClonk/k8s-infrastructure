#!/bin/bash
set -e
set -u
set -o pipefail
source ../../setup.sh

# diff
kapp app-change list -a kube-state-metrics
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f ../values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kube-state-metrics -c --diff-run -f -
