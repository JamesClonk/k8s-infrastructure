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
####### firewall #######################################################################################################
########################################################################################################################
if [ "${HETZNER_FIREWALL_ENABLED}" == "true" ]; then
echo "checking for firewall [${HETZNER_FIREWALL_NAME}] ..."
hcloud firewall list -o noheader | grep "${HETZNER_FIREWALL_NAME}" 1>/dev/null \
	|| (echo "creating ${HETZNER_FIREWALL_NAME} ..." \
		&& cat firewall_rules.json | envsubst | hcloud firewall create --name "${HETZNER_FIREWALL_NAME}" --rules-file - \
		&& sleep 30)
# wait half a minute for firewall to be ready for sure

# setup firewall
echo "setting rules for firewall ..."
cat firewall_rules.json | envsubst | hcloud firewall replace-rules "${HETZNER_FIREWALL_NAME}" --rules-file - 1>/dev/null

echo "applying firewall to server [${HETZNER_NODE_NAME}] ..."
hcloud firewall apply-to-resource "${HETZNER_FIREWALL_NAME}" --server "${HETZNER_NODE_NAME}" --type server 1>/dev/null || true
echo " "
fi
