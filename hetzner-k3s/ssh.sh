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
####### ssh ############################################################################################################
########################################################################################################################
echo "connecting via ssh to [${HETZNER_NODE_NAME}] ..."
ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP}
