#!/bin/bash
set -e
set -u
source ../../setup.sh

# status
kapp app-change list -a grafana
kapp inspect -a grafana --tree
