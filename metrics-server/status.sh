#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp app-change list -a metrics-server
kapp inspect -a metrics-server --tree
