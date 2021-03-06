#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp app-change list -a kubernetes-dashboard
cat values.yml |
	envsubst -no-unset -no-empty |
	ytt --ignore-unknown-comments -f templates -f - --data-value-file dashboard.kubeconfig="${KUBECONFIG}" |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kubernetes-dashboard -c --diff-run -f -
