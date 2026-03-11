#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a cert-manager
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a cert-manager -c --diff-run -f -
