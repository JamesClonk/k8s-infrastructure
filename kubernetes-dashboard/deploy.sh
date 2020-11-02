#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [kubernetes-dashboard] ..."
DASHBOARD_BASIC_AUTH=$(basic_auth ${DASHBOARD_BASIC_AUTH_USERNAME} ${DASHBOARD_BASIC_AUTH_PASSWORD})
cat values.yml | envsubst -no-unset -no-empty | ytt --ignore-unknown-comments -f templates -f - | kapp -y deploy -a kubernetes-dashboard -c -f -
kapp -y app-change garbage-collect -a kubernetes-dashboard --max 5
echo "done!"
