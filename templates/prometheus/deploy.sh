#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [prometheus] ..."
build/render.sh
ytt --ignore-unknown-comments -f templates -f values.yaml |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a prometheus -c -y -f -
kapp app-change garbage-collect -a prometheus --max 5 -y
