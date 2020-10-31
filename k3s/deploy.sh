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
hcloud ssh-key list -o noheader | grep "${SSH_KEY_NAME}" 1>/dev/null \
	|| hcloud ssh-key create --name "${SSH_KEY_NAME}" --public-key "${SSH_KEY}"
echo " "

########################################################################################################################
####### private network ################################################################################################
########################################################################################################################
echo "checking for private network [${PRIVATE_NETWORK_NAME}] ..."
hcloud network list -o noheader | grep "${PRIVATE_NETWORK_NAME}" 1>/dev/null \
	|| hcloud network create --name "${PRIVATE_NETWORK_NAME}" --ip-range "${PRIVATE_NETWORK_RANGE}"

echo "checking private network [${PRIVATE_NETWORK_NAME}] for ip-range [${PRIVATE_NETWORK_RANGE}] ..."
hcloud network describe k8s-private -o format='{{.IPRange}}' | grep "${PRIVATE_NETWORK_RANGE}" 1>/dev/null \
	|| hcloud network change-ip-range --ip-range "${PRIVATE_NETWORK_RANGE}" "${PRIVATE_NETWORK_NAME}"

echo "checking private network [${PRIVATE_NETWORK_NAME}] for subnet [${PRIVATE_NETWORK_SUBNET}] ..."
hcloud network describe k8s-private -o format='{{.Subnets}}' | grep "${PRIVATE_NETWORK_SUBNET}" 1>/dev/null \
	|| hcloud network add-subnet "${PRIVATE_NETWORK_NAME}" --ip-range "${PRIVATE_NETWORK_SUBNET}" \
	--type "cloud" --network-zone "${PRIVATE_NETWORK_ZONE}"
echo " "

########################################################################################################################
####### server #########################################################################################################
########################################################################################################################
echo "checking for server [${NODE_NAME}] ..."
hcloud server list -o noheader | grep "${NODE_NAME}" 1>/dev/null \
	|| hcloud server create --name "${NODE_NAME}" --type "${NODE_TYPE}" --image "${NODE_IMAGE}" \
	--ssh-key "${SSH_KEY_NAME}" --network "${PRIVATE_NETWORK_NAME}" --location "${NODE_LOCATION}"
echo " "

########################################################################################################################
####### kubernetes #####################################################################################################
########################################################################################################################
echo "installing/upgrading k3s on server [${NODE_NAME}] ..."
NODE_IP=$(hcloud server describe ${NODE_NAME} -o format='{{ .PublicNet.IPv4.IP }}')
cat $HOME/.ssh/known_hosts | grep "${NODE_IP}" 1>/dev/null || ssh-keyscan "${NODE_IP}" >> $HOME/.ssh/known_hosts
hcloud server ssh "${NODE_NAME}" \
	"curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3S_VERSION}' INSTALL_K3S_EXEC='--disable=traefik --disable=servicelb' sh -"
echo " "
mkdir -p $HOME/.kube || true
hcloud server ssh "${NODE_NAME}" 'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${NODE_IP}/g" > "$HOME/.kube/${NODE_NAME}"
kubectl --kubeconfig="$HOME/.kube/${NODE_NAME}" cluster-info
echo " "
kubectl --kubeconfig="$HOME/.kube/${NODE_NAME}" get nodes
echo " "
kubectl --kubeconfig="$HOME/.kube/${NODE_NAME}" top nodes
echo " "
