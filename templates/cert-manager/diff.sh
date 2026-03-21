#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a cert-manager
ytt --ignore-unknown-comments -f templates |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a cert-manager -c --diff-run -f -
