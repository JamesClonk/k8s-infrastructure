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
####### ssh key ########################################################################################################
########################################################################################################################
echo "checking for ssh-key [{{{ .hetzner.ssh.key_name }}}] ..."
hcloud ssh-key list -o noheader | grep "{{{ .hetzner.ssh.key_name }}}" 1>/dev/null ||
	hcloud ssh-key create --name "{{{ .hetzner.ssh.key_name }}}" --public-key "{{{ .hetzner.ssh.public_key }}}"
echo " "

########################################################################################################################
####### private network ################################################################################################
########################################################################################################################
echo "checking for private network [{{{ .hetzner.private_network.name }}}] ..."
hcloud network list -o noheader | grep "{{{ .hetzner.private_network.name }}}" 1>/dev/null ||
	hcloud network create --name "{{{ .hetzner.private_network.name }}}" --ip-range "{{{ .hetzner.private_network.range }}}"

echo "checking private network [{{{ .hetzner.private_network.name }}}] for ip-range [{{{ .hetzner.private_network.range }}}] ..."
hcloud network describe "{{{ .hetzner.private_network.name }}}" -o format='{{.IPRange}}' | grep "{{{ .hetzner.private_network.range }}}" 1>/dev/null ||
	hcloud network change-ip-range --ip-range "{{{ .hetzner.private_network.range }}}" "{{{ .hetzner.private_network.name }}}"

echo "checking private network [{{{ .hetzner.private_network.name }}}] for subnet [{{{ .hetzner.private_network.subnet }}}] ..."
hcloud network describe "{{{ .hetzner.private_network.name }}}" -o format='{{.Subnets}}' | grep "{{{ .hetzner.private_network.subnet }}}" 1>/dev/null ||
	hcloud network add-subnet "{{{ .hetzner.private_network.name }}}" --ip-range "{{{ .hetzner.private_network.subnet }}}" \
		--type "cloud" --network-zone "{{{ .hetzner.private_network.zone }}}"
echo " "

########################################################################################################################
####### server #########################################################################################################
########################################################################################################################
echo "checking for server [{{{ .hetzner.node.name }}}] ..."
hcloud server list -o noheader | grep "{{{ .hetzner.node.name }}}" 1>/dev/null ||
	(hcloud server create --name "{{{ .hetzner.node.name }}}" --type "${HETZNER_NODE_TYPE}" --image "${HETZNER_NODE_IMAGE}" \
		--ssh-key "{{{ .hetzner.ssh.key_name }}}" --network "{{{ .hetzner.private_network.name }}}" --location "${HETZNER_NODE_LOCATION}" \
		--user-data-from-file "cloud-init.conf" && rm -f "${KUBECONFIG}" && echo "waiting for server to be ready ..." && sleep 177)
# wait for a while for server when newly created to be ready for sure

# get server-ip, public and private
retry 5 10 hcloud server ip "{{{ .hetzner.node.name }}}"
HETZNER_NODE_IP=$(hcloud server ip "{{{ .hetzner.node.name }}}")
HETZNER_NODE_PRIVATE_IP=$(hcloud server list -o json | jq -r ".[] | select(.name == \"{{{ .hetzner.node.name }}}\") | .private_net[0].ip")
echo "server IPs: ${HETZNER_NODE_IP}, ${HETZNER_NODE_PRIVATE_IP}"
echo " "

echo "verifying DNS entry for [${INGRESS_DOMAIN}] ..."
INGRESS_DOMAIN_IP=$(dig "${INGRESS_DOMAIN}" +short)
if [ "${INGRESS_DOMAIN_IP}" != "${HETZNER_NODE_IP}" ]; then
	echo "Error, actual server IP [${HETZNER_NODE_IP}] and DNS response IP [${INGRESS_DOMAIN_IP}] of [${INGRESS_DOMAIN}] do not match!"
	echo "Please fix the DNS records!"
	exit 1
fi

########################################################################################################################
####### wireguard ######################################################################################################
########################################################################################################################
echo "checking wireguard ..."

# (re)start local wireguard client connection to server
sudo wg-quick down "${LOCAL_WIREGUARD_FILE}" || true
sudo wg-quick up "${LOCAL_WIREGUARD_FILE}"

# test if we can still reach SSH from outside
export HETZNER_FIREWALL_LOADED_ALREADY="false"
nc -vz "${HETZNER_NODE_IP}" 22333 -w5 || export HETZNER_FIREWALL_LOADED_ALREADY="true" # if failure, then firewall already blocks ssh and wireguard should be active by now

# setup if no firewall yet
if [ "${HETZNER_FIREWALL_LOADED_ALREADY}" == "false" ]; then
	# add server-ip to ssh known_hosts, otherwise no initial ssh setup commands will work
	cat "$HOME/.ssh/known_hosts" 2>/dev/null | grep "${HETZNER_NODE_IP}" 1>/dev/null ||
		(echo "adding ${HETZNER_NODE_IP} to ssh known_hosts ..." &&
			ssh-keyscan -p 22333 "${HETZNER_NODE_IP}" 2>/dev/null >>"$HOME/.ssh/known_hosts" && echo " " || true)

	echo "configuring wireguard ..."
	retry 2 2 hcloud server ssh -p 22333 "{{{ .hetzner.node.name }}}" \
		"cat > /etc/wireguard/hetzner0.conf << EOF
$(cat wireguard_remote.conf)
EOF"
	retry 2 2 hcloud server ssh -p 22333 "{{{ .hetzner.node.name }}}" "systemctl enable --now wg-quick@hetzner0"
	sleep 2

	# also do an ssh known_hosts entry via private-ip now
	cat "$HOME/.ssh/known_hosts" 2>/dev/null | grep "${HETZNER_NODE_PRIVATE_IP}" 1>/dev/null ||
		(echo "adding ${HETZNER_NODE_PRIVATE_IP} to ssh known_hosts ..." && ssh-keyscan -p 22333 "${HETZNER_NODE_PRIVATE_IP}" 2>/dev/null >>"$HOME/.ssh/known_hosts" && echo " ")
fi
echo " "

########################################################################################################################
####### SSH ############################################################################################################
########################################################################################################################
echo "checking ssh ..."

# setup if no firewall yet
if [ "${HETZNER_FIREWALL_LOADED_ALREADY}" == "false" ]; then
	# custom SSH configuration
	echo "configuring sshd ..."
	### note: some of these security settings are not needed anymore since SSH will be behind wireguard access
	# # remove weak moduli
	# retry 2 2 hcloud server ssh -p 22333 "{{{ .hetzner.node.name }}}" 'awk '\''$5 >= 3071'\'' /etc/ssh/moduli > /etc/ssh/moduli.safe; mv /etc/ssh/moduli.safe /etc/ssh/moduli'
	# # regenerate the RSA and ED25519 keys
	# retry 2 2 hcloud server ssh -p 22333 "{{{ .hetzner.node.name }}}" "rm /etc/ssh/ssh_host_*; ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ''; ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''"
	# stop listening to public IP, local only from now on! (access is handled via wireguard)
	retry 2 2 hcloud server ssh -p 22333 "{{{ .hetzner.node.name }}}" "sed 's/# ListenAddress xyz/ListenAddress ${HETZNER_NODE_PRIVATE_IP}/g' -i /etc/ssh/sshd_config.d/ssh-kubernetes.conf"
	retry 2 2 hcloud server ssh -p 22333 "{{{ .hetzner.node.name }}}" "systemctl restart ssh.service"
	sleep 5
fi
echo " "

########################################################################################################################
####### firewall #######################################################################################################
########################################################################################################################
# setup firewall
./firewall.sh

########################################################################################################################
####### server config ##################################################################################################
########################################################################################################################
# get rid of idiotic systemd-resolved
retry 2 2 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} "systemctl stop systemd-resolved; systemctl disable systemd-resolved"
retry 2 2 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} "rm -f /etc/resolv.conf"
retry 2 2 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} \
	"cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 1.0.0.1
nameserver 8.8.4.4
EOF"
echo " "

# setup crontab
echo "checking crontab ..."
# check if crontab is already setup
ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} "crontab -l | grep 'sbin/reboot' 1>/dev/null" ||
	(
		echo "setting up crontab ..."
		retry 2 2 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} \
			"cat > /root/crontab.conf << EOF
# m h  dom mon dow   command
00 07 * * 1 /usr/sbin/reboot

EOF"
		retry 2 2 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} "crontab < /root/crontab.conf"
	)
ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} "crontab -l"
echo " "

########################################################################################################################
####### floating-ip ####################################################################################################
########################################################################################################################
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	echo "checking for floating-ip [${HETZNER_FLOATING_IP_NAME}] ..."
	hcloud floating-ip list -o noheader | grep "${HETZNER_FLOATING_IP_NAME}" 1>/dev/null ||
		(hcloud floating-ip create --name "${HETZNER_FLOATING_IP_NAME}" --type "ipv4" \
			--home-location "${HETZNER_NODE_LOCATION}" --server "{{{ .hetzner.node.name }}}" &&
			sleep 15)
	# wait 15 seconds for floating-ip to be ready for sure

	# is it now assigned?
	hcloud floating-ip describe "${HETZNER_FLOATING_IP_NAME}" -o format='{{.Server.ID}}' 2>/dev/null ||
		(hcloud floating-ip assign "${HETZNER_FLOATING_IP_NAME}" "{{{ .hetzner.node.name }}}" &&
			sleep 15)
	# wait 15 seconds for floating-ip to be assigned for sure

	# add floating-ip to server network interfaces
	HETZNER_FLOATING_IP=$(hcloud floating-ip describe "${HETZNER_FLOATING_IP_NAME}" -o format='{{.IP}}')
	ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} "cat /etc/netplan/60-floating-ip.yaml | grep '${HETZNER_FLOATING_IP}' 1>/dev/null" ||
		(ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} \
			"cat > /etc/netplan/60-floating-ip.yaml << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses:
      - ${HETZNER_FLOATING_IP}/32
EOF" &&
			hcloud server reboot "{{{ .hetzner.node.name }}}" && sleep 30)
	# wait half a minute for server to be ready for sure

	# add floating-ip to ssh known_hosts
	cat "$HOME/.ssh/known_hosts" 2>/dev/null | grep "${HETZNER_FLOATING_IP}" 1>/dev/null ||
		ssh-keyscan -p 22333 "${HETZNER_FLOATING_IP}" 2>/dev/null >>"$HOME/.ssh/known_hosts"
	echo " "
fi

########################################################################################################################
####### load-balancer ###################################################################################################
########################################################################################################################
if [ "${HETZNER_LOADBALANCER_ENABLED}" == "true" ]; then
	echo "checking for load-balancer [${HETZNER_LOADBALANCER_NAME}] ..."
	hcloud load-balancer list -o noheader | grep "${HETZNER_LOADBALANCER_NAME}" 1>/dev/null ||
		(hcloud load-balancer create --name "${HETZNER_LOADBALANCER_NAME}" --type "${HETZNER_LOADBALANCER_TYPE}" \
			--location "${HETZNER_NODE_LOCATION}" --network-zone "{{{ .hetzner.private_network.zone }}}" &&
			sleep 15)
	# wait 15 seconds for load-balancer to be ready for sure

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" | grep "${HETZNER_LOADBALANCER_NAME}" 1>/dev/null ||
		hcloud load-balancer attach-to-network --network "{{{ .hetzner.private_network.name }}}" "${HETZNER_LOADBALANCER_NAME}"

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{.Services}}' | grep "http 80 80" 1>/dev/null ||
		(hcloud load-balancer add-service "${HETZNER_LOADBALANCER_NAME}" \
			--protocol "http" --listen-port 80 --destination-port 80 &&
			hcloud load-balancer update-service "${HETZNER_LOADBALANCER_NAME}" \
				--protocol "http" --listen-port 80 --destination-port 80 --health-check-http-status-codes "2??,3??,404")

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{.Services}}' | grep "tcp 443 443" 1>/dev/null ||
		hcloud load-balancer add-service "${HETZNER_LOADBALANCER_NAME}" \
			--protocol "tcp" --listen-port 443 --destination-port 443

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{index .Targets 0}}' | grep "server" 1>/dev/null ||
		hcloud load-balancer add-target "${HETZNER_LOADBALANCER_NAME}" --server "{{{ .hetzner.node.name }}}" --use-private-ip
	echo " "
fi

########################################################################################################################
####### kubernetes #####################################################################################################
########################################################################################################################
echo "installing/upgrading k3s on server [{{{ .hetzner.node.name }}}] ..."

retry 10 10 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} \
	"curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='{{{ .hetzner.k3s.version }}}' INSTALL_K3S_EXEC='--tls-san=${HETZNER_NODE_PRIVATE_IP} --disable=traefik --disable=servicelb' sh -"
echo " "
test -f "${KUBECONFIG}" || sleep 60 # wait a moment if this looks like it is k3s' first startup

mkdir -p $HOME/.kube || true
HETZNER_K3S_IP="${HETZNER_NODE_PRIVATE_IP}"
if [ "${HETZNER_FLOATING_IP_ENABLED}" == "true" ]; then
	HETZNER_K3S_IP="${HETZNER_FLOATING_IP}"
fi
retry 5 10 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} \
	'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${HETZNER_K3S_IP}/g" >"${KUBECONFIG}"
chmod 600 "${KUBECONFIG}"

retry 10 30 kubectl cluster-info
echo " "
retry 10 60 kubectl get nodes
echo " "
retry 10 60 kubectl top nodes
echo " "
