#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp --tty --color app-change list -a cert-manager
kapp --tty --color inspect -a cert-manager --tree
