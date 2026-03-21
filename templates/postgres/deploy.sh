#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [postgres] ..."
ytt --ignore-unknown-comments -f templates -f values.yaml |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a postgres -c -y -f -
kapp app-change garbage-collect -a postgres --max 5 -y
