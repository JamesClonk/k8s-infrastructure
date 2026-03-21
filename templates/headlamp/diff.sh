#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a headlamp
build/render.sh
ytt --ignore-unknown-comments -f templates -f values.yaml -f - --data-value-file dashboard.kubeconfig="${KUBECONFIG}" |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a headlamp -c --diff-run -f -
