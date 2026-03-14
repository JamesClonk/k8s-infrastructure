#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [envoy-gateway] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f ${CONFIGURATION_FILE} -f - --data-value envoy.gateway_ip="${INGRESS_DOMAIN_IP}" |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a envoy-gateway -c -y -f -
kapp app-change garbage-collect -a envoy-gateway --max 5 -y
