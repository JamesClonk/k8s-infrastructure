#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp app-change list -a postgres
kapp inspect -a postgres --tree
