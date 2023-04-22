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
# get server-ip
HETZNER_NODE_IP=$(hcloud server ip "${HETZNER_NODE_NAME}")

# what is the current SSH port?
nc -vz "${HETZNER_NODE_IP}" "${HETZNER_SSH_PORT}" || export HETZNER_SSH_PORT="22" # fallback to default

# add server-ip to ssh known_hosts
cat "$HOME/.ssh/known_hosts" 2>/dev/null | grep "${HETZNER_NODE_IP}" 1>/dev/null \
	|| (echo "adding ${HETZNER_NODE_IP} to ssh known_hosts ..." \
		&& ssh-keyscan -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_IP}" 2>/dev/null >> "$HOME/.ssh/known_hosts")
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
echo "rebooting server [${HETZNER_NODE_NAME}] ..."

hcloud server reboot "${HETZNER_NODE_NAME}"
echo " "

mkdir -p $HOME/.kube || true
HETZNER_K3S_IP="${HETZNER_NODE_IP}"
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	HETZNER_K3S_IP="${HETZNER_FLOATING_IP}"
fi
retry 15 45 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
	'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${HETZNER_K3S_IP}/g" > "${KUBECONFIG}"
chmod 600 "${KUBECONFIG}"

retry 15 45 kubectl cluster-info
echo " "
retry 15 60 kubectl get nodes
echo " "
retry 15 60 kubectl top nodes
echo " "
