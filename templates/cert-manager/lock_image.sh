#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# lock image
echo "locking images for [cert-manager] ..."
ytt --ignore-unknown-comments -f templates |
	kbld -f - --lock-output "image.lock.yaml"
cp -f image.lock.yaml ../../templates/cert-manager/.
