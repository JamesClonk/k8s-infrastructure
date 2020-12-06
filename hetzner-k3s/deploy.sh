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
	|| hcloud ssh-key create --name "${HETZNER_SSH_KEY_NAME}" --public-key "${HETZNER_PUBLIC_SSH_KEY}"
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

# get server-ip
retry 5 10 hcloud server ip "${HETZNER_NODE_NAME}"
HETZNER_NODE_IP=$(hcloud server ip "${HETZNER_NODE_NAME}")

# what is the current SSH port?
nc -vz "${HETZNER_NODE_IP}" "${HETZNER_SSH_PORT}" || export HETZNER_SSH_PORT="22" # fallback to default

# add server-ip to ssh known_hosts
cat "$HOME/.ssh/known_hosts" 2>/dev/null | grep "${HETZNER_NODE_IP}" 1>/dev/null \
	|| (echo "adding ${HETZNER_NODE_IP} to ssh known_hosts ..." \
		&& ssh-keyscan -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_IP}" 2>/dev/null >> "$HOME/.ssh/known_hosts")
echo " "

# custom SSH configuration
echo "configuring sshd ..."
retry 5 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
"cat > /etc/ssh/sshd_config << EOF
Include /etc/ssh/sshd_config.d/*.conf
Port 22333
PermitRootLogin yes
MaxAuthTries 2
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF"
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "systemctl restart sshd" && sleep 5
export HETZNER_SSH_PORT="22333" # now the port definitely should have changed

# get rid of idiotic systemd-resolved
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
"cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 1.0.0.1
nameserver 8.8.4.4
EOF"
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "systemctl stop systemd-resolved; systemctl disable systemd-resolved"
echo " "

# setup fail2ban
echo "installing fail2ban ..."
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "apt-get update; apt-get install fail2ban; systemctl enable fail2ban"
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
"cat > /etc/fail2ban/jail.d/defaults-debian.conf << EOF
[DEFAULT]
bantime  = 15m
[sshd]
enabled = true
port = 22333
EOF"
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "systemctl restart fail2ban"
echo " "

# setup firewall
echo "checking firewall ..."
# check if ufw is already installed and in status active, only setup if not
hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "ufw status | grep active 1>/dev/null" ||
	(
	# why this?
	# because ufw is extremely flaky and has a lot of problems with xtables locks from docker/kubernetes,
	# so we want to avoid running ufw commands at all cost
	retry 5 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "apt-get install ufw"
	# 22333: ssh, 80/443: ingress, 6443: kube-api, 32222: syncthing
	retry 10 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
		"ufw default deny incoming \
		  && ufw allow ${HETZNER_SSH_PORT}/tcp \
		  && ufw allow 80/tcp \
		  && ufw allow 443/tcp \
		  && ufw allow 6443/tcp \
		  && ufw allow 32222/tcp \
		  && ufw allow 32222/udp \
		  && ufw allow from 10.0.0.0/8 \
		  && ufw logging off"
	retry 10 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "sleep 2 && ufw --force enable"
	retry 10 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "sleep 2 && ufw reload && sleep 1"
	)
retry 5 5 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "ufw status"
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

	# is it now assigned?
	hcloud floating-ip describe "${HETZNER_FLOATING_IP_NAME}" -o format='{{.Server.ID}}' 2>/dev/null \
		|| (hcloud floating-ip assign "${HETZNER_FLOATING_IP_NAME}" "${HETZNER_NODE_NAME}" \
		&& sleep 15)
		# wait 15 seconds for floating-ip to be assigned for sure

	# add floating-ip to server network interfaces
	HETZNER_FLOATING_IP=$(hcloud floating-ip describe "${HETZNER_FLOATING_IP_NAME}" -o format='{{.IP}}')
	hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" "cat /etc/netplan/60-floating-ip.yaml | grep '${HETZNER_FLOATING_IP}' 1>/dev/null" \
		|| (hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
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
	cat "$HOME/.ssh/known_hosts" 2>/dev/null | grep "${HETZNER_FLOATING_IP}" 1>/dev/null \
		|| ssh-keyscan -p "${HETZNER_SSH_PORT}" "${HETZNER_FLOATING_IP}" 2>/dev/null >> "$HOME/.ssh/known_hosts"
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

retry 10 10 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
	"curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${HETZNER_K3S_VERSION}' INSTALL_K3S_EXEC='--disable=traefik --disable=servicelb' sh -"
echo " "
test -f "${KUBECONFIG}" || sleep 30 # wait a moment if this looks like it is k3s' first startup

mkdir -p $HOME/.kube || true
HETZNER_K3S_IP="${HETZNER_NODE_IP}"
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	HETZNER_K3S_IP="${HETZNER_FLOATING_IP}"
fi
retry 5 10 hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
	'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${HETZNER_K3S_IP}/g" > "${KUBECONFIG}"
chmod 600 "${KUBECONFIG}"

retry 10 30 kubectl cluster-info
echo " "
retry 10 60 kubectl get nodes
echo " "
retry 10 60 kubectl top nodes
echo " "
