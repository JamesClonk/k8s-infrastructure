#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# diff
kapp app-change list -a envoy-gateway
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yaml -f - --data-value envoy.gateway_ip="${INGRESS_DOMAIN_IP}" |
	kbld -f - -f image.lock.yaml |
	kapp deploy -a envoy-gateway -c --diff-run -f -
