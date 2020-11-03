#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp app-change list -a cert-manager
kapp inspect -a cert-manager --tree
