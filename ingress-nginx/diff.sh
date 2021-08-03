#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp app-change list -a ingress-nginx
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a ingress-nginx -c --diff-run -f -
