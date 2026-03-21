#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a envoy-gateway
kapp inspect -a envoy-gateway --tree
