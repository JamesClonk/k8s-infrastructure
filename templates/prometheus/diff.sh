#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a prometheus
build/render.sh
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f - |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a prometheus -c --diff-run -f -
