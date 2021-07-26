#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp app-change list -a kube-system
sops -d ../secrets.sops |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ../configuration.yml -f - |
	kapp deploy -a kube-system -c --diff-run -f -
