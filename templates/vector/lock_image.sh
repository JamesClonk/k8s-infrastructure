#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# lock image
echo "locking images for [vector] ..."
build/render.sh
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f - |
	kbld -f - --lock-output "image.lock.yaml"
cp -f image.lock.yaml ../../templates/vector/.
