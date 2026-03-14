#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# lock image
echo "locking images for [envoy-gateway] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f ${CONFIGURATION_FILE} -f - --data-value envoy.gateway_ip="${INGRESS_DOMAIN_IP}" |
	kbld -f - --lock-output "image.lock.yaml"
