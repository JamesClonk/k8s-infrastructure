#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [vector] ..."
build/render.sh
ytt --ignore-unknown-comments -f templates -f values.yaml |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a vector -c -y -f -
kapp app-change garbage-collect -a vector --max 5 -y
