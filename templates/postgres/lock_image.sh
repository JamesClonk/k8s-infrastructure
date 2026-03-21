#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# lock image
echo "locking images for [postgres] ..."
ytt --ignore-unknown-comments -f templates -f values.yaml |
	kbld -f - --lock-output "image.lock.yaml"
cp -f image.lock.yaml ../../templates/postgres/.
