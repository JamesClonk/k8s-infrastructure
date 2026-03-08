#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a envoy-gateway
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a envoy-gateway -c --diff-run -f -
