#!/bin/bash
set -e
set -u
source ../../setup.sh

# status
kapp app-change list -a kube-state-metrics
kapp inspect -a kube-state-metrics --tree
