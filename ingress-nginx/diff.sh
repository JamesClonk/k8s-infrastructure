#!/bin/bash
set -e
source ../setup.sh

# diff
kapp app-change list -a ingress-nginx
ytt --ignore-unknown-comments -f templates -f values.yml | kapp deploy -a ingress-nginx -c --diff-run -f -
