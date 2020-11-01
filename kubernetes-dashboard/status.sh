#!/bin/bash
set -e
source ../setup.sh

# status
kapp app-change list -a kubernetes-dashboard
kapp inspect -a kubernetes-dashboard --tree
