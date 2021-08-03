#!/bin/bash
set -e
set -u
source ../setup.sh

# lock image
echo "locking images for [hcloud-csi] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - |
	kbld -f - --lock-output "image.lock.yml"
