#!/bin/bash
set -e
set -u
source ../setup.sh

# diff
kapp --color app-change list -a ingress-nginx
ytt --ignore-unknown-comments -f templates -f values.yml |
	kbld -f - -f image.lock.yml |
	kapp --color deploy -a ingress-nginx -c --diff-run -f -
