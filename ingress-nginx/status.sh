#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a ingress-nginx
kapp inspect -a ingress-nginx --tree
