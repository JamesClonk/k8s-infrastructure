#!/bin/bash
set -e
set -u
source ../../setup.sh

# lock image
echo "locking images for [kube-state-metrics] ..."
ytt --ignore-unknown-comments -f templates -f ../values.yml | kbld -f - --lock-output "image.lock.yml"
