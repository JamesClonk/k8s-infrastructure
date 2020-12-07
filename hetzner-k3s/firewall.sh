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

# setup firewall
echo "setting up firewall ..."
retry 5 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "apt-get update; apt-get install ufw"
# 22333: ssh, 80/443: ingress, 6443: kube-api, 32222: syncthing
retry 10 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
	"ufw allow ${HETZNER_SSH_PORT}/tcp \
	  && ufw default deny incoming \
	  && ufw allow ${HETZNER_SSH_PORT}/tcp \
	  && ufw allow 80/tcp \
	  && ufw allow 443/tcp \
	  && ufw allow 6443/tcp \
	  && ufw allow 32222/tcp \
	  && ufw allow 32222/udp \
	  && ufw allow from 10.0.0.0/8 \
	  && ufw logging off \
	  && sleep 2 && ufw --force enable"
retry 10 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "sleep 2 && ufw reload && sleep 1"
retry 10 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "ufw status"
echo " "

# Why is this a separate job?
# As it turns out ufw is badly written and has quite a bit of issues with iptables xtables locking.
# Those issues will start to appear more and more frequently once your Kubernetes node starts to have some network policies applied to it.
# To avoid ufw locking up the entire node I've taken the ufw-rule-apply/reload step out of the main pipeline and put it here as an on-demand separate step.
