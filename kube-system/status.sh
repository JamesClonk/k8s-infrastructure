#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp app-change list -a kube-system
kapp inspect -a kube-system --tree
