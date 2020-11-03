#!/bin/bash
set -e
set -u
source ../setup.sh

# status
kapp --tty --color app-change list -a ingress-nginx
kapp --tty --color inspect -a ingress-nginx --tree
