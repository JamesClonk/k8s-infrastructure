#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a kube-system
ytt --ignore-unknown-comments -f templates -f values.yaml |
	kapp deploy -a kube-system -c --diff-run -f -
