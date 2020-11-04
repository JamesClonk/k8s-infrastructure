#!/bin/bash
set -e
set -u
source ../../setup.sh

# diff
kapp app-change list -a prometheus-msteams
cat ../values.yml |
	envsubst -no-unset -no-empty |
	ytt --ignore-unknown-comments -f templates -f - |
	kbld -f - -f image.lock.yml |
	kapp deploy -a prometheus-msteams -c --diff-run -f -
