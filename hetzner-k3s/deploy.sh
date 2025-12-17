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
echo "checking for ssh-key [${HETZNER_SSH_KEY_NAME}] ..."
hcloud ssh-key list -o noheader | grep "${HETZNER_SSH_KEY_NAME}" 1>/dev/null ||
	hcloud ssh-key create --name "${HETZNER_SSH_KEY_NAME}" --public-key "${HETZNER_PUBLIC_SSH_KEY}"
echo " "

########################################################################################################################
####### private network ################################################################################################
########################################################################################################################
echo "checking for private network [${HETZNER_PRIVATE_NETWORK_NAME}] ..."
hcloud network list -o noheader | grep "${HETZNER_PRIVATE_NETWORK_NAME}" 1>/dev/null ||
	hcloud network create --name "${HETZNER_PRIVATE_NETWORK_NAME}" --ip-range "${HETZNER_PRIVATE_NETWORK_RANGE}"

echo "checking private network [${HETZNER_PRIVATE_NETWORK_NAME}] for ip-range [${HETZNER_PRIVATE_NETWORK_RANGE}] ..."
hcloud network describe "${HETZNER_PRIVATE_NETWORK_NAME}" -o format='{{.IPRange}}' | grep "${HETZNER_PRIVATE_NETWORK_RANGE}" 1>/dev/null ||
	hcloud network change-ip-range --ip-range "${HETZNER_PRIVATE_NETWORK_RANGE}" "${HETZNER_PRIVATE_NETWORK_NAME}"

echo "checking private network [${HETZNER_PRIVATE_NETWORK_NAME}] for subnet [${HETZNER_PRIVATE_NETWORK_SUBNET}] ..."
hcloud network describe "${HETZNER_PRIVATE_NETWORK_NAME}" -o format='{{.Subnets}}' | grep "${HETZNER_PRIVATE_NETWORK_SUBNET}" 1>/dev/null ||
	hcloud network add-subnet "${HETZNER_PRIVATE_NETWORK_NAME}" --ip-range "${HETZNER_PRIVATE_NETWORK_SUBNET}" \
		--type "cloud" --network-zone "${HETZNER_PRIVATE_NETWORK_ZONE}"
echo " "

########################################################################################################################
####### server #########################################################################################################
########################################################################################################################
# prepare cloud-init file
cat >$HOME/.tmp/cloud-init.conf <<EOF
#cloud-config

package_update: true
package_upgrade: true
packages:
- wireguard

write_files:
- path: /etc/ssh/sshd_config.d/ssh-kubernetes.conf
  content: |
    # ListenAddress xyz
    Port 22333
    Protocol 2
    HostKey /etc/ssh/ssh_host_rsa_key
    HostKey /etc/ssh/ssh_host_ed25519_key
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group18-sha512,diffie-hellman-group16-sha512
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
    HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com
    PermitRootLogin yes
    MaxAuthTries 2
    LoginGraceTime 15
    ClientAliveInterval 300
    ClientAliveCountMax 2
    PubkeyAuthentication yes
    PasswordAuthentication no
    PermitEmptyPasswords no
    ChallengeResponseAuthentication no
    KbdInteractiveAuthentication no
    KerberosAuthentication no
    GSSAPIAuthentication no

runcmd:
- reboot
EOF

echo "checking for server [${HETZNER_NODE_NAME}] ..."
hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" 1>/dev/null ||
	(hcloud server create --name "${HETZNER_NODE_NAME}" --type "${HETZNER_NODE_TYPE}" --image "${HETZNER_NODE_IMAGE}" \
		--ssh-key "${HETZNER_SSH_KEY_NAME}" --network "${HETZNER_PRIVATE_NETWORK_NAME}" --location "${HETZNER_NODE_LOCATION}" \
		--user-data-from-file "$HOME/.tmp/cloud-init.conf" && rm -f "${KUBECONFIG}" && sleep 77)
# wait a minute for server to be ready for sure
rm -f "$HOME/.tmp/cloud-init.conf"

# get server-ip, public and private
retry 5 10 hcloud server ip "${HETZNER_NODE_NAME}"
HETZNER_NODE_IP=$(hcloud server ip "${HETZNER_NODE_NAME}")
HETZNER_NODE_PRIVATE_IP=$(hcloud server list -o json | jq -r ".[] | select(.name == \"${HETZNER_NODE_NAME}\") | .private_net[0].ip")
echo "server IPs: ${HETZNER_NODE_IP}, ${HETZNER_NODE_PRIVATE_IP}"
echo " "

########################################################################################################################
####### wireguard ######################################################################################################
########################################################################################################################
echo "checking wireguard ..."

# (re)start local wireguard client connection to server
wg-quick down "${LOCAL_WIREGUARD_FILE}" || true
wg-quick up "${LOCAL_WIREGUARD_FILE}"

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
	retry 2 2 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" \
		"cat > /etc/wireguard/hetzner0.conf << EOF
# server
[Interface]
Address = ${HETZNER_WIREGUARD_SERVER_IP}/24
ListenPort = ${HETZNER_WIREGUARD_SERVER_PORT}
PrivateKey = ${HETZNER_WIREGUARD_SERVER_PRIVATE_KEY}

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens+ -j MASQUERADE
PostUp = sysctl -w -q net.ipv4.ip_forward=1; sysctl -w -q net.ipv4.conf.all.forwarding=1
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens+ -j MASQUERADE
PostDown = sysctl -w -q net.ipv4.ip_forward=0; sysctl -w -q net.ipv4.conf.all.forwarding=0
SaveConfig = false

# client
[Peer]
PublicKey = ${HETZNER_WIREGUARD_CLIENT_PUBLIC_KEY}
AllowedIPs = ${HETZNER_WIREGUARD_CLIENT_IP}/32
EOF"
	retry 2 2 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "systemctl enable --now wg-quick@hetzner0"
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
	# retry 2 2 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" 'awk '\''$5 >= 3071'\'' /etc/ssh/moduli > /etc/ssh/moduli.safe; mv /etc/ssh/moduli.safe /etc/ssh/moduli'
	# # regenerate the RSA and ED25519 keys
	# retry 2 2 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "rm /etc/ssh/ssh_host_*; ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ''; ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''"
	# stop listening to public IP, local only from now on! (access is handled via wireguard)
	retry 2 2 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "sed 's/# ListenAddress xyz/ListenAddress ${HETZNER_NODE_PRIVATE_IP}/g' -i /etc/ssh/sshd_config.d/ssh-kubernetes.conf"
	retry 2 2 hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" "systemctl restart ssh.service"
	sleep 5
fi
echo " "

########################################################################################################################
####### firewall #######################################################################################################
########################################################################################################################
# setup firewall
./firewall.sh
exit 1 # TODO: remove if firewall is correct

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
00 08 * * 1 /usr/sbin/reboot

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
			--home-location "${HETZNER_NODE_LOCATION}" --server "${HETZNER_NODE_NAME}" &&
			sleep 15)
	# wait 15 seconds for floating-ip to be ready for sure

	# is it now assigned?
	hcloud floating-ip describe "${HETZNER_FLOATING_IP_NAME}" -o format='{{.Server.ID}}' 2>/dev/null ||
		(hcloud floating-ip assign "${HETZNER_FLOATING_IP_NAME}" "${HETZNER_NODE_NAME}" &&
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
			hcloud server reboot "${HETZNER_NODE_NAME}" && sleep 30)
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
			--location "${HETZNER_NODE_LOCATION}" --network-zone "${HETZNER_PRIVATE_NETWORK_ZONE}" &&
			sleep 15)
	# wait 15 seconds for load-balancer to be ready for sure

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" | grep "${HETZNER_LOADBALANCER_NAME}" 1>/dev/null ||
		hcloud load-balancer attach-to-network --network "${HETZNER_PRIVATE_NETWORK_NAME}" "${HETZNER_LOADBALANCER_NAME}"

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{.Services}}' | grep "http 80 80" 1>/dev/null ||
		(hcloud load-balancer add-service "${HETZNER_LOADBALANCER_NAME}" \
			--protocol "http" --listen-port 80 --destination-port 80 &&
			hcloud load-balancer update-service "${HETZNER_LOADBALANCER_NAME}" \
				--protocol "http" --listen-port 80 --destination-port 80 --health-check-http-status-codes "2??,3??,404")

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{.Services}}' | grep "tcp 443 443" 1>/dev/null ||
		hcloud load-balancer add-service "${HETZNER_LOADBALANCER_NAME}" \
			--protocol "tcp" --listen-port 443 --destination-port 443

	hcloud load-balancer describe "${HETZNER_LOADBALANCER_NAME}" -o format='{{index .Targets 0}}' | grep "server" 1>/dev/null ||
		hcloud load-balancer add-target "${HETZNER_LOADBALANCER_NAME}" --server "${HETZNER_NODE_NAME}" --use-private-ip
	echo " "
fi

########################################################################################################################
####### kubernetes #####################################################################################################
########################################################################################################################
echo "installing/upgrading k3s on server [${HETZNER_NODE_NAME}] ..."

retry 10 10 ssh -p 22333 root@${HETZNER_NODE_PRIVATE_IP} \
	"curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${HETZNER_K3S_VERSION}' INSTALL_K3S_EXEC='--disable=traefik --disable=servicelb' sh -"
echo " "
test -f "${KUBECONFIG}" || sleep 60 # wait a moment if this looks like it is k3s' first startup

mkdir -p $HOME/.kube || true
HETZNER_K3S_IP="${HETZNER_NODE_IP}"
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
