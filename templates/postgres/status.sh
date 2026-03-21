#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# status
kapp app-change list -a postgres
kapp inspect -a postgres --tree
