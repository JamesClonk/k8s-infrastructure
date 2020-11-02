#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp app-change list -a cert-manager
cat values.yml | envsubst -no-unset -no-empty | ytt --ignore-unknown-comments -f templates -f - | kapp deploy -a cert-manager -c --diff-run -f -
