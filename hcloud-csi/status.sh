#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a hcloud-csi
kapp inspect -a hcloud-csi --tree
