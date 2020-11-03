#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp --color app-change list -a ingress-nginx
kapp --color inspect -a ingress-nginx --tree
