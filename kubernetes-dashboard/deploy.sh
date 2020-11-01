#!/bin/bash
set -e
source ../setup.sh

# deploy
echo "deploying [kubernetes-dashboard] ..."
cat values.yml | envsubst -no-unset -no-empty | ytt --ignore-unknown-comments -f templates -f - | kapp -y deploy -a kubernetes-dashboard -c -f -
kapp -y app-change garbage-collect -a kubernetes-dashboard --max 5
echo "done!"
