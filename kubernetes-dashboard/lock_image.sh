#!/bin/bash
set -e
set -u
source ../setup.sh

# lock image
echo "locking images for [kubernetes-dashboard] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - --data-value-file dashboard.kubeconfig="${KUBECONFIG}" |
	kbld -f - --lock-output "image.lock.yml"
