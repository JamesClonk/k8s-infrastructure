#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp --color app-change list -a cert-manager
kapp --color inspect -a cert-manager --tree
