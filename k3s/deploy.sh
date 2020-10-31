#!/bin/bash
set -e
source ../setup.sh
source configuration.env

# deploy
if [ -z "${HCLOUD_TOKEN}" ]; then
	echo "HCLOUD_TOKEN is missing"
	exit 1
fi
# create context if not exists
# hcloud context list -o noheader | grep "${PROJECT}" || hcloud context create ${PROJECT}

echo "checking for private network [${PRIVATE_NETWORK_NAME}] ..."
hcloud network list -o noheader | grep "${PRIVATE_NETWORK_NAME}" \
	|| hcloud network create --name "${PRIVATE_NETWORK_NAME}" --ip-range "${PRIVATE_NETWORK_RANGE}"

echo "checking private network [${PRIVATE_NETWORK_NAME}] for ip-range [${PRIVATE_NETWORK_RANGE}] ..."
hcloud network describe k8s-private -o format='{{.IPRange}}' | grep "${PRIVATE_NETWORK_RANGE}" \
	|| hcloud network change-ip-range --ip-range "${PRIVATE_NETWORK_RANGE}" "${PRIVATE_NETWORK_NAME}"

echo "checking private network [${PRIVATE_NETWORK_NAME}] for subnet [${PRIVATE_NETWORK_SUBNET}] ..."
hcloud network describe k8s-private -o format='{{.Subnets}}' | grep "${PRIVATE_NETWORK_SUBNET}" \
	|| hcloud network add-subnet "${PRIVATE_NETWORK_NAME}" --ip-range "${PRIVATE_NETWORK_SUBNET}" --type "cloud" --network-zone "${PRIVATE_NETWORK_ZONE}"

