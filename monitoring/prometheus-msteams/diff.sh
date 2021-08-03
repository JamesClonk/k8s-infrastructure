#!/bin/bash
set -e
set -u
source ../../setup.sh

# diff
kapp app-change list -a prometheus-msteams
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f ../values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a prometheus-msteams -c --diff-run -f -
