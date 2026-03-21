#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# lock image
echo "locking images for [headlamp] ..."
build/render.sh
ytt --ignore-unknown-comments -f templates -f values.yaml -f - --data-value-file dashboard.kubeconfig="${KUBECONFIG}" |
	kbld -f - --lock-output "image.lock.yaml"
cp -f image.lock.yaml ../../templates/headlamp/.
