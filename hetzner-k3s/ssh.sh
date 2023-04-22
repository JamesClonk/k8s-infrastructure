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
####### ssh ############################################################################################################
########################################################################################################################
echo "connecting via ssh to [${HETZNER_NODE_NAME}] ..."
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}"
