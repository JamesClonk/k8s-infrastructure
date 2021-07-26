#!/bin/bash
set -e
set -u
source ../../setup.sh

# lock image
echo "locking images for [prometheus] ..."
sops -d ../../secrets.sops |
	ytt --ignore-unknown-comments -f templates -f ../values.yml -f ../../configuration.yml -f - |
	kbld -f - --lock-output "image.lock.yml"
