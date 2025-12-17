#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# check for HCLOUD_TOKEN
if [ -z "${HCLOUD_TOKEN}" ]; then
	echo "HCLOUD_TOKEN is missing"
	exit 1
fi

########################################################################################################################
####### server #########################################################################################################
########################################################################################################################
# get private server-ip
HETZNER_NODE_PRIVATE_IP=$(hcloud server list -o json | jq -r ".[] | select(.name == \"${HETZNER_NODE_NAME}\") | .private_net[0].ip")

# add server-ip to ssh known_hosts
cat "$HOME/.ssh/known_hosts" 2>/dev/null | grep "${HETZNER_NODE_PRIVATE_IP}" 1>/dev/null ||
	(echo "adding ${HETZNER_NODE_PRIVATE_IP} to ssh known_hosts ..." &&
		ssh-keyscan -p 22333 "${HETZNER_NODE_PRIVATE_IP}" 2>/dev/null >>"$HOME/.ssh/known_hosts")
echo " "

########################################################################################################################
####### floating-ip ####################################################################################################
########################################################################################################################
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	# get floating-ip
	HETZNER_FLOATING_IP=$(hcloud floating-ip describe "${HETZNER_FLOATING_IP_NAME}" -o format='{{.IP}}')
fi

########################################################################################################################
####### kubernetes #####################################################################################################
########################################################################################################################
echo "restarting k3s on server [${HETZNER_NODE_NAME}] ..."

hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" \
	"curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${HETZNER_K3S_VERSION}' INSTALL_K3S_EXEC='--disable=traefik --disable=servicelb' sh -"
echo " "

# fix iptables issues (https://github.com/k3s-io/k3s/issues/535)
echo "clearing iptables ..."
retry 7 7 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "iptables -P INPUT ACCEPT"
retry 7 7 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "iptables -P FORWARD ACCEPT"
retry 7 7 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "iptables -P OUTPUT ACCEPT"
retry 7 7 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "iptables -t nat -F"
retry 7 7 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "iptables -t mangle -F"
retry 7 7 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "iptables -F"
retry 7 7 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "iptables -X"

# restarting k3s
echo "restarting k3s ..."
hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "systemctl restart k3s"
hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "systemctl status k3s"
echo " "

mkdir -p $HOME/.kube || true
HETZNER_K3S_IP=$(hcloud server ip "${HETZNER_NODE_NAME}")
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	HETZNER_K3S_IP="${HETZNER_FLOATING_IP}"
fi
retry 5 10 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" \
	'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${HETZNER_K3S_IP}/g" >"${KUBECONFIG}"
chmod 600 "${KUBECONFIG}"

retry 15 45 kubectl cluster-info
echo " "
retry 15 60 kubectl get nodes
echo " "
retry 15 60 kubectl top nodes
echo " "
