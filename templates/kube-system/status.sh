#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a kube-system
kapp inspect -a kube-system --tree
