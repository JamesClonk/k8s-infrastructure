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

########################################################################################################################
####### ssh key ########################################################################################################
########################################################################################################################
echo "checking for ssh-key [${SSH_KEY_NAME}] ..."
hcloud ssh-key list -o noheader | grep "${SSH_KEY_NAME}" \
	|| hcloud ssh-key create --name "${SSH_KEY_NAME}" --public-key "${SSH_KEY}"
echo " "

########################################################################################################################
####### private network ################################################################################################
########################################################################################################################
echo "checking for private network [${PRIVATE_NETWORK_NAME}] ..."
hcloud network list -o noheader | grep "${PRIVATE_NETWORK_NAME}" \
	|| hcloud network create --name "${PRIVATE_NETWORK_NAME}" --ip-range "${PRIVATE_NETWORK_RANGE}"

echo "checking private network [${PRIVATE_NETWORK_NAME}] for ip-range [${PRIVATE_NETWORK_RANGE}] ..."
hcloud network describe k8s-private -o format='{{.IPRange}}' | grep "${PRIVATE_NETWORK_RANGE}" \
	|| hcloud network change-ip-range --ip-range "${PRIVATE_NETWORK_RANGE}" "${PRIVATE_NETWORK_NAME}"

echo "checking private network [${PRIVATE_NETWORK_NAME}] for subnet [${PRIVATE_NETWORK_SUBNET}] ..."
hcloud network describe k8s-private -o format='{{.Subnets}}' | grep "${PRIVATE_NETWORK_SUBNET}" \
	|| hcloud network add-subnet "${PRIVATE_NETWORK_NAME}" --ip-range "${PRIVATE_NETWORK_SUBNET}" \
	--type "cloud" --network-zone "${PRIVATE_NETWORK_ZONE}"
echo " "

########################################################################################################################
####### server #########################################################################################################
########################################################################################################################
echo "checking for server [${NODE_NAME}] ..."
hcloud server list -o noheader | grep "${NODE_NAME}" \
	|| hcloud server create --name "${NODE_NAME}" --type "${NODE_TYPE}" --image "${NODE_IMAGE}" \
	--ssh-key "${SSH_KEY_NAME}" --network "${PRIVATE_NETWORK_NAME}" --location "${NODE_LOCATION}"

echo "installing k3s on server [${NODE_NAME}] ..."
# TODO: query k8s api, if OK then no need to reinstall k3s??? or do we run k3s upgrade command here?
hcloud server ssh "${NODE_NAME}" 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --disable=servicelb" sh -'
mkdir -p $HOME/.kube
SERVER_IP=$(hcloud server describe ${NODE_NAME} -o format='{{ .PublicNet.IPv4.IP }}')
#hcloud server ssh "${NODE_NAME}" 'cat /etc/rancher/k3s/k3s.yaml' | perl -pe "s/127.0.0.1/$IP/g" > "$HOME/.kube/${NODE_NAME}"

