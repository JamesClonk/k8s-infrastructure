#!/bin/bash
set -e
source ../setup.sh

# status
kapp app-change list -a ingress-nginx
kapp inspect -a ingress-nginx --tree
