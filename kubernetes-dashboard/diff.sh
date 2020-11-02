#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp app-change list -a kubernetes-dashboard
DASHBOARD_BASIC_AUTH=$(basic_auth ${DASHBOARD_BASIC_AUTH_USERNAME} ${DASHBOARD_BASIC_AUTH_PASSWORD})
cat values.yml | envsubst -no-unset -no-empty | ytt --ignore-unknown-comments -f templates -f - | kapp deploy -a kubernetes-dashboard -c --diff-run -f -
