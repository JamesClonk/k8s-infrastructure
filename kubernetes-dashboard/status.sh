#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp app-change list -a kubernetes-dashboard
kapp inspect -a kubernetes-dashboard --tree
