#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp app-change list -a kube-system
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kapp deploy -a kube-system -c --diff-run -f -
