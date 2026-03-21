#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a cert-manager
kapp inspect -a cert-manager --tree
