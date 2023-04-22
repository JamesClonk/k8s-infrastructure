#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a oauth2-proxy
kapp inspect -a oauth2-proxy --tree
