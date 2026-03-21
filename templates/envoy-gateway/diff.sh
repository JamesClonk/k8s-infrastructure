#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a envoy-gateway
ytt --ignore-unknown-comments -f templates -f values.yaml |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a envoy-gateway -c --diff-run -f -
