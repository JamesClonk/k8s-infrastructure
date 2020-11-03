#!/bin/bash
set -e
set -u
source ../setup.sh

# check for HCLOUD_TOKEN
if [ -z "${HCLOUD_TOKEN}" ]; then
	echo "HCLOUD_TOKEN is missing"
	exit 1
fi

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
hcloud network describe "${HETZNER_PRIVATE_NETWORK_NAME}" -o format='{{.IPRange}}' | grep "${HETZNER_PRIVATE_NETWORK_RANGE}" 1>/dev/null \
	|| hcloud network change-ip-range --ip-range "${HETZNER_PRIVATE_NETWORK_RANGE}" "${HETZNER_PRIVATE_NETWORK_NAME}"

echo "checking private network [${HETZNER_PRIVATE_NETWORK_NAME}] for subnet [${HETZNER_PRIVATE_NETWORK_SUBNET}] ..."
hcloud network describe "${HETZNER_PRIVATE_NETWORK_NAME}" -o format='{{.Subnets}}' | grep "${HETZNER_PRIVATE_NETWORK_SUBNET}" 1>/dev/null \
	|| hcloud network add-subnet "${HETZNER_PRIVATE_NETWORK_NAME}" --ip-range "${HETZNER_PRIVATE_NETWORK_SUBNET}" \
	--type "cloud" --network-zone "${HETZNER_PRIVATE_NETWORK_ZONE}"
echo " "

########################################################################################################################
####### server #########################################################################################################
########################################################################################################################
echo "checking for server [${HETZNER_NODE_NAME}] ..."
hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" 1>/dev/null \
	|| (hcloud server create --name "${HETZNER_NODE_NAME}" --type "${HETZNER_NODE_TYPE}" --image "${HETZNER_NODE_IMAGE}" \
	--ssh-key "${HETZNER_SSH_KEY_NAME}" --network "${HETZNER_PRIVATE_NETWORK_NAME}" --location "${HETZNER_NODE_LOCATION}" \
	&& rm -f "${KUBECONFIG}" && sleep 30)
	# wait half a minute for server to be ready for sure

# add server-ip to ssh known_hosts
retry 5 10 hcloud server ip "${HETZNER_NODE_NAME}"
HETZNER_NODE_IP=$(hcloud server ip "${HETZNER_NODE_NAME}")
cat "$HOME/.ssh/known_hosts" | grep "${HETZNER_NODE_IP}" 1>/dev/null || ssh-keyscan "${HETZNER_NODE_IP}" >> "$HOME/.ssh/known_hosts"
echo " "

########################################################################################################################
####### floating-ip ####################################################################################################
########################################################################################################################
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	echo "checking for floating-ip [${HETZNER_FLOATING_IP_NAME}] ..."
	hcloud floating-ip list -o noheader | grep "${HETZNER_FLOATING_IP_NAME}" 1>/dev/null \
		|| (hcloud floating-ip create --name "${HETZNER_FLOATING_IP_NAME}" --type "ipv4" \
		--home-location "${HETZNER_NODE_LOCATION}" --server "${HETZNER_NODE_NAME}" \
		&& sleep 15)
		# wait 15 seconds for floating-ip to be ready for sure

	# add floating-ip to server network interfaces
	HETZNER_FLOATING_IP=$(hcloud floating-ip describe "${HETZNER_FLOATING_IP_NAME}" -o format='{{.IP}}')
	hcloud server ssh "${HETZNER_NODE_NAME}" "cat /etc/netplan/60-floating-ip.yaml | grep '${HETZNER_FLOATING_IP}' 1>/dev/null" \
		|| (hcloud server ssh "${HETZNER_NODE_NAME}" \
	"cat > /etc/netplan/60-floating-ip.yaml << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses:
      - ${HETZNER_FLOATING_IP}/32
EOF" \
		&& hcloud server reboot "${HETZNER_NODE_NAME}" && sleep 30)
		# wait half a minute for server to be ready for sure

	# add floating-ip to ssh known_hosts
	cat "$HOME/.ssh/known_hosts" | grep "${HETZNER_FLOATING_IP}" 1>/dev/null || ssh-keyscan "${HETZNER_FLOATING_IP}" >> "$HOME/.ssh/known_hosts"
	echo " "
fi

########################################################################################################################
####### load-balancer ###################################################################################################
########################################################################################################################
if [ "${HETZNER_LOADBALANCER_ENABLED}" == "true" ]; then
	echo "checking for load-balancer [${HETZNER_LOADBALANCER_NAME}] ..."
	hcloud load-balancer list -o noheader | grep "${HETZNER_LOADBALANCER_NAME}" 1>/dev/null \
		|| (hcloud load-balancer create --name "${HETZNER_LOADBALANCER_NAME}" --type "${HETZNER_LOADBALANCER_TYPE}" \
		--location "${HETZNER_NODE_LOCATION}" --network-zone "${HETZNER_PRIVATE_NETWORK_ZONE}" \
		&& sleep 15)
		# wait 15 seconds for load-balancer to be ready for sure

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" | grep "${HETZNER_LOADBALANCER_NAME}" 1>/dev/null \
		|| hcloud load-balancer attach-to-network --network "${HETZNER_PRIVATE_NETWORK_NAME}" "${HETZNER_LOADBALANCER_NAME}"

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{.Services}}' | grep "http 80 80" 1>/dev/null \
		|| (hcloud load-balancer add-service "${HETZNER_LOADBALANCER_NAME}" \
		--protocol "http" --listen-port 80 --destination-port 80 \
		&& hcloud load-balancer update-service "${HETZNER_LOADBALANCER_NAME}" \
		--protocol "http" --listen-port 80 --destination-port 80 --health-check-http-status-codes "2??,3??,404")

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{.Services}}' | grep "tcp 443 443" 1>/dev/null \
		|| hcloud load-balancer add-service "${HETZNER_LOADBALANCER_NAME}" \
		--protocol "tcp" --listen-port 443 --destination-port 443

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{index .Targets 0}}' | grep "server" 1>/dev/null \
		|| hcloud load-balancer add-target "${HETZNER_LOADBALANCER_NAME}" --server "${HETZNER_NODE_NAME}" --use-private-ip
	echo " "
fi

########################################################################################################################
####### kubernetes #####################################################################################################
########################################################################################################################
echo "installing/upgrading k3s on server [${HETZNER_NODE_NAME}] ..."

HETZNER_K3S_IP="${HETZNER_NODE_IP}"
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	HETZNER_K3S_IP="${HETZNER_FLOATING_IP}"
fi
retry 10 10 hcloud server ssh "${HETZNER_NODE_NAME}" \
	"curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${HETZNER_K3S_VERSION}' INSTALL_K3S_EXEC='--disable=traefik --disable=servicelb' sh -"
echo " "
test -f "${KUBECONFIG}" || sleep 30 # wait a moment if this looks like it is k3s' first startup
mkdir -p $HOME/.kube || true
retry 5 5 hcloud server ssh "${HETZNER_NODE_NAME}" \
	'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${HETZNER_K3S_IP}/g" > "${KUBECONFIG}"

retry 10 30 kubectl cluster-info
echo " "
retry 10 30 kubectl get nodes
echo " "
retry 10 30 kubectl top nodes
echo " "
