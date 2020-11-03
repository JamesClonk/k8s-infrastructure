#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp --color app-change list -a kubernetes-dashboard
kapp --color inspect -a kubernetes-dashboard --tree
