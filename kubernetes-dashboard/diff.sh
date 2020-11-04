#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp app-change list -a kubernetes-dashboard
INGRESS_BASIC_AUTH=$(basic_auth "${INGRESS_BASIC_AUTH_USERNAME}" "${INGRESS_BASIC_AUTH_PASSWORD}")
cat values.yml |
	envsubst -no-unset -no-empty |
	ytt --ignore-unknown-comments -f templates -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kubernetes-dashboard -c --diff-run -f -
