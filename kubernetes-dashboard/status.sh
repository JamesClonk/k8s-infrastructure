#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a kubernetes-dashboard
kapp inspect -a kubernetes-dashboard --tree
