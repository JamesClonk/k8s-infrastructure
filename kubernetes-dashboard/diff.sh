#!/bin/bash
set -e
source ../setup.sh

# diff
kapp app-change list -a kubernetes-dashboard
cat values.yml | envsubst -no-unset -no-empty | ytt --ignore-unknown-comments -f templates -f - | kapp deploy -a kubernetes-dashboard -c --diff-run -f -
