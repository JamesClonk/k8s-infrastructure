#!/bin/bash
set -e
source ../setup.sh

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
echo "checking for ssh-key [${HETZNER_SSH_KEY_NAME}] ..."
hcloud ssh-key list -o noheader | grep "${HETZNER_SSH_KEY_NAME}" 1>/dev/null \
	|| hcloud ssh-key create --name "${HETZNER_SSH_KEY_NAME}" --public-key "${HETZNER_SSH_KEY}"
echo " "

########################################################################################################################
####### private network ################################################################################################
########################################################################################################################
echo "checking for private network [${HETZNER_PRIVATE_NETWORK_NAME}] ..."
hcloud network list -o noheader | grep "${HETZNER_PRIVATE_NETWORK_NAME}" 1>/dev/null \
	|| hcloud network create --name "${HETZNER_PRIVATE_NETWORK_NAME}" --ip-range "${HETZNER_PRIVATE_NETWORK_RANGE}"

echo "checking private network [${HETZNER_PRIVATE_NETWORK_NAME}] for ip-range [${HETZNER_PRIVATE_NETWORK_RANGE}] ..."
hcloud network describe k8s-private -o format='{{.IPRange}}' | grep "${HETZNER_PRIVATE_NETWORK_RANGE}" 1>/dev/null \
	|| hcloud network change-ip-range --ip-range "${HETZNER_PRIVATE_NETWORK_RANGE}" "${HETZNER_PRIVATE_NETWORK_NAME}"

echo "checking private network [${HETZNER_PRIVATE_NETWORK_NAME}] for subnet [${HETZNER_PRIVATE_NETWORK_SUBNET}] ..."
hcloud network describe k8s-private -o format='{{.Subnets}}' | grep "${HETZNER_PRIVATE_NETWORK_SUBNET}" 1>/dev/null \
	|| hcloud network add-subnet "${HETZNER_PRIVATE_NETWORK_NAME}" --ip-range "${HETZNER_PRIVATE_NETWORK_SUBNET}" \
	--type "cloud" --network-zone "${HETZNER_PRIVATE_NETWORK_ZONE}"
echo " "

########################################################################################################################
####### server #########################################################################################################
########################################################################################################################
echo "checking for server [${HETZNER_NODE_NAME}] ..."
hcloud server list -o noheader | grep "${NHETZNER_ODE_NAME}" 1>/dev/null \
	|| (hcloud server create --name "${HETZNER_NODE_NAME}" --type "${HETZNER_NODE_TYPE}" --image "${HETZNER_NODE_IMAGE}" \
	--ssh-key "${HETZNER_SSH_KEY_NAME}" --network "${HETZNER_PRIVATE_NETWORK_NAME}" --location "${HETZNER_NODE_LOCATION}" \
	&& sleep 30) # wait half a minute for server to be started up
echo " "

########################################################################################################################
####### kubernetes #####################################################################################################
########################################################################################################################
echo "installing/upgrading k3s on server [${HETZNER_NODE_NAME}] ..."

retry 5 15 hcloud server ip ${HETZNER_NODE_NAME}
HETZNER_NODE_IP=$(hcloud server ip ${HETZNER_NODE_NAME})
cat $HOME/.ssh/known_hosts | grep "${HETZNER_NODE_IP}" 1>/dev/null || ssh-keyscan "${HETZNER_NODE_IP}" >> $HOME/.ssh/known_hosts

retry 10 10 hcloud server ssh "${HETZNER_NODE_NAME}" \
	"curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${HETZNER_K3S_VERSION}' INSTALL_K3S_EXEC='--disable=traefik --disable=servicelb' sh -"
echo " "
mkdir -p $HOME/.kube || true
retry 5 5 hcloud server ssh "${HETZNER_NODE_NAME}" \
	'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${HETZNER_NODE_IP}/g" > "${KUBECONFIG}"

retry 10 30 kubectl cluster-info
echo " "
retry 10 30 kubectl get nodes
echo " "
retry 10 30 kubectl top nodes
echo " "
