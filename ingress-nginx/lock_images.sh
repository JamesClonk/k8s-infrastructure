#!/bin/bash
set -e
source ../setup.sh

# lock images
ytt --ignore-unknown-comments -f templates -f - |
	kbld -f - --lock-output "image.lock.yml"
kbld relocate -f "image.lock.yml" --repository docker.io/jamesclonk/ingress-nginx --lock-output "image.lock.yml"
