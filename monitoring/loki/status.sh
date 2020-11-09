#!/bin/bash
set -e
set -u
source ../../setup.sh

# status
kapp app-change list -a loki
kapp inspect -a loki --tree
