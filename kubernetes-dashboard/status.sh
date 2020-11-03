#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp --tty --color app-change list -a kubernetes-dashboard
kapp --tty --color inspect -a kubernetes-dashboard --tree
