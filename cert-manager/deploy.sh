#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [cert-manager] ..."
cat values.yml | envsubst -no-unset -no-empty | ytt --ignore-unknown-comments -f templates -f - | kapp -y deploy -a cert-manager -c -f -
kapp -y app-change garbage-collect -a cert-manager --max 5
echo "done!"
