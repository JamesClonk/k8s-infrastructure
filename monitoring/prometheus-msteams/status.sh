#!/bin/bash
set -e
set -u
set -o pipefail
source ../../setup.sh

# status
kapp app-change list -a prometheus-msteams
kapp inspect -a prometheus-msteams --tree
