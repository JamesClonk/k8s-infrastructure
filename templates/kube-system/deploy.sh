#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [kube-system] ..."
ytt --ignore-unknown-comments -f templates |
	kapp deploy -a kube-system -c -y -f -
kapp app-change garbage-collect -a kube-system --max 5 -y
