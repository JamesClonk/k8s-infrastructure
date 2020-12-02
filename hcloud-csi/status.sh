#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp app-change list -a hcloud-csi
kapp inspect -a hcloud-csi --tree
