#!/bin/bash
set -e
set -u
set -o pipefail
source $(dirname ${BASH_SOURCE[0]})/.env* 1>/dev/null 2>&1 || true # source any hidden env config files if available

########################################################################################################################
# environment configuration
########################################################################################################################
export CONFIGURATION_FILE="$(dirname ${BASH_SOURCE[0]})/configuration.yml"
export SECRETS_FILE="$(dirname ${BASH_SOURCE[0]})/secrets.sops"
export KUBECONFIG="$HOME/.kube/k8s-infrastructure"
export LOCAL_WIREGUARD_FILE="$HOME/.tmp/hetzner0.conf"

########################################################################################################################
# helper functions
########################################################################################################################
function basic_auth() {
	local -r username="$1"
	shift
	local -r password="$1"
	shift
	echo "${username}:$(openssl passwd -apr1 \"${password}\")"
}

function retry() {
	local -r -i max_attempts="$1"
	shift
	local -r -i sleep_time="$1"
	shift
	local -i attempt_num=1
	until "$@"; do
		if ((attempt_num == max_attempts)); then
			echo "#$attempt_num failures!"
			exit 1
		else
			echo "#$((attempt_num++)): trying again in $sleep_time seconds ..."
			sleep $sleep_time
		fi
	done
}

function install_tool {
	local -r tool_name="$1"
	shift
	local -r tool_url="$1"
	shift
	local -r tool_checksum="$1"
	shift
	if [ ! -f "$HOME/bin/${tool_name}" ]; then
		echo "downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}" 2>/dev/null
		chmod +x "$HOME/bin/${tool_name}"

		found_checksum=$(sha256sum -z "$HOME/bin/${tool_name}" | awk '{print $1;}')
		echo "${found_checksum}" | grep "${tool_checksum}" >/dev/null || (echo "checksum failed for [${tool_name}], it was [${found_checksum}] instead of the expected [${tool_checksum}]" && rm -f "$HOME/bin/${tool_name}" && exit 1)
	fi
}

function install_tool_from_tarball {
	local -r tool_path="$1"
	shift
	local -r tool_name="$1"
	shift
	local -r tool_url="$1"
	shift
	local -r tool_checksum="$1"
	shift
	if [ ! -f "$HOME/bin/${tool_name}" ]; then
		echo "downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}.tgz" 2>/dev/null
		echo "unpacking [${tool_name}.tgz] ..."
		STRIP_COMPONENTS=$(echo "${tool_path}" | awk -F"/" '{print NF-1}')
		tar -xvzf "$HOME/bin/${tool_name}.tgz" --strip-components=${STRIP_COMPONENTS} -C "$HOME/bin/" "${tool_path}" >/dev/null
		chmod +x "$HOME/bin/${tool_name}"
		rm -f "$HOME/bin/${tool_name}.tgz"

		found_checksum=$(sha256sum -z "$HOME/bin/${tool_name}" | awk '{print $1;}')
		echo "${found_checksum}" | grep "${tool_checksum}" >/dev/null || (echo "checksum failed for [${tool_name}], it was [${found_checksum}] instead of the expected [${tool_checksum}]" && rm -f "$HOME/bin/${tool_name}" && exit 1)
	fi
}

########################################################################################################################
# $HOME/bin
########################################################################################################################
if [ ! -d "$HOME/bin" ]; then mkdir "$HOME/bin"; fi
export PATH="$HOME/bin:$PATH"

########################################################################################################################
# install tools
########################################################################################################################
install_tool "sops" "https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64" "775f1384d55decfad228e7196a3f683791914f92a473f78fc47700531c29dfef"
install_tool "kubectl" "https://dl.k8s.io/release/v1.34.2/bin/linux/amd64/kubectl" "9591f3d75e1581f3f7392e6ad119aab2f28ae7d6c6e083dc5d22469667f27253"
install_tool "kapp" "https://github.com/carvel-dev/kapp/releases/download/v0.65.0/kapp-linux-amd64" "9cb88745d189bbfe2423771d68f50f7222ca33187350470857cca124d3341233"
install_tool "ytt" "https://github.com/carvel-dev/ytt/releases/download/v0.52.1/ytt-linux-amd64" "490f138ae5b6864071d3c20a5a231e378cee7487cd4aeffc79dbf66718e65408"
install_tool "vendir" "https://github.com/carvel-dev/vendir/releases/download/v0.45.0/vendir-linux-amd64" "d60ad65bbd0658d377f2dcf57b3119f16c5a3a7eeaf80019a3d243a620404d7e"
install_tool "kbld" "https://github.com/carvel-dev/kbld/releases/download/v0.47.0/kbld-linux-amd64" "f9cf1d84ed8dd7c19133044e15939e62c9929ecf1115edeb7275f45b99e2d1ac"
install_tool "imgpkg" "https://github.com/carvel-dev/imgpkg/releases/download/v0.47.0/imgpkg-linux-amd64" "7602b6af24a818265dcb2cc0dc7f6117a3591f26e2c266f294800f99ae433da1"
install_tool "yq" "https://github.com/mikefarah/yq/releases/download/v4.49.2/yq_linux_amd64" "be2c0ddcf426b6a231648610ec5d1666ae50e9f6473e82f6486f9f4cb6e3e2f7"
install_tool "jq" "https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-amd64" "020468de7539ce70ef1bceaf7cde2e8c4f2ca6c3afb84642aabc5c97d9fc2a0d"
install_tool "kind" "https://github.com/kubernetes-sigs/kind/releases/download/v0.30.0/kind-linux-amd64" "517ab7fc89ddeed5fa65abf71530d90648d9638ef0c4cde22c2c11f8097b8889"
install_tool "cmctl" "https://github.com/cert-manager/cmctl/releases/download/v2.4.0/cmctl_linux_amd64" "57d12fc2c5fd7a9f2df372130c7da7f995855a06058ca41a2b6c66c26a6ca7ae"
install_tool_from_tarball "hcloud" "hcloud" "https://github.com/hetznercloud/cli/releases/download/v1.57.0/hcloud-linux-amd64.tar.gz" "6852b9dde7e5d413c734d4ae134f631c2ec7380d4a6ad524227f42dd5ecdcd23"
install_tool_from_tarball "linux-amd64/helm" "helm" "https://get.helm.sh/helm-v3.19.3-linux-amd64.tar.gz" "39244958465c4be60f3815b3cf5ddc1904024cef3753bfd54667bfaefd8a0d1b"
install_tool_from_tarball "age/age" "age" "https://github.com/FiloSottile/age/releases/download/v1.2.1/age-v1.2.1-linux-amd64.tar.gz" "aaec874ed903da4b02a9d503778ae05ee5005b2acc0f4a4cf10e5d0f17fd4384"
install_tool_from_tarball "age/age-keygen" "age-keygen" "https://github.com/FiloSottile/age/releases/download/v1.2.1/age-v1.2.1-linux-amd64.tar.gz" "50f849de5f05dc136de3dba623dd2b7e166e7badb9d4e3d83da88f2dbdb2d439"

########################################################################################################################
# git config
########################################################################################################################
git config --local core.hooksPath .githooks/
git config --local diff.sopsdiffer.textconv "sops -d"

########################################################################################################################
# hetzner cloud - k3s configuration
########################################################################################################################
export HCLOUD_TOKEN=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.token' -)

export HETZNER_SSH_KEY_NAME=$(yq -e eval '.configuration.hetzner.ssh.key_name' ${CONFIGURATION_FILE})
export HETZNER_PUBLIC_SSH_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.ssh.public_key' -)
export HETZNER_PRIVATE_SSH_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.ssh.private_key' -)

export HETZNER_WIREGUARD_SERVER_RANGE=$(yq -e eval '.configuration.hetzner.wireguard.server.range' ${CONFIGURATION_FILE})
export HETZNER_WIREGUARD_SERVER_IP=$(yq -e eval '.configuration.hetzner.wireguard.server.ip' ${CONFIGURATION_FILE})
export HETZNER_WIREGUARD_SERVER_PORT=$(yq -e eval '.configuration.hetzner.wireguard.server.port' ${CONFIGURATION_FILE})
export HETZNER_WIREGUARD_SERVER_PUBLIC_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.wireguard.server.public_key' -)
export HETZNER_WIREGUARD_SERVER_PRIVATE_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.wireguard.server.private_key' -)

export HETZNER_WIREGUARD_CLIENT_IP=$(yq -e eval '.configuration.hetzner.wireguard.client.ip' ${CONFIGURATION_FILE})
export HETZNER_WIREGUARD_CLIENT_PUBLIC_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.wireguard.client.public_key' -)
export HETZNER_WIREGUARD_CLIENT_PRIVATE_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.wireguard.client.private_key' -)

export HETZNER_PRIVATE_NETWORK_NAME=$(yq -e eval '.configuration.hetzner.private_network.name' ${CONFIGURATION_FILE})
export HETZNER_PRIVATE_NETWORK_RANGE=$(yq -e eval '.configuration.hetzner.private_network.range' ${CONFIGURATION_FILE})
export HETZNER_PRIVATE_NETWORK_SUBNET=$(yq -e eval '.configuration.hetzner.private_network.subnet' ${CONFIGURATION_FILE})
export HETZNER_PRIVATE_NETWORK_ZONE=$(yq -e eval '.configuration.hetzner.private_network.zone' ${CONFIGURATION_FILE})

export HETZNER_NODE_NAME=$(yq -e eval '.configuration.hetzner.node.name' ${CONFIGURATION_FILE})
export HETZNER_NODE_TYPE=$(yq -e eval '.configuration.hetzner.node.type' ${CONFIGURATION_FILE})
export HETZNER_NODE_IMAGE=$(yq -e eval '.configuration.hetzner.node.image' ${CONFIGURATION_FILE})
export HETZNER_NODE_LOCATION=$(yq -e eval '.configuration.hetzner.node.location' ${CONFIGURATION_FILE})

export HETZNER_FIREWALL_ENABLED=$(yq -e eval '.configuration.hetzner.firewall.enabled' ${CONFIGURATION_FILE})
export HETZNER_FIREWALL_NAME=$(yq -e eval '.configuration.hetzner.firewall.name' ${CONFIGURATION_FILE})

export HETZNER_FLOATING_IP_ENABLED=$(yq -e eval '.configuration.hetzner.floating_ip.enabled' ${CONFIGURATION_FILE})
export HETZNER_FLOATING_IP_NAME=$(yq -e eval '.configuration.hetzner.floating_ip.name' ${CONFIGURATION_FILE})

export HETZNER_LOADBALANCER_ENABLED=$(yq -e eval '.configuration.hetzner.loadbalancer.enabled' ${CONFIGURATION_FILE})
export HETZNER_LOADBALANCER_NAME=$(yq -e eval '.configuration.hetzner.loadbalancer.name' ${CONFIGURATION_FILE})
export HETZNER_LOADBALANCER_TYPE=$(yq -e eval '.configuration.hetzner.loadbalancer.type' ${CONFIGURATION_FILE})

export HETZNER_K3S_VERSION=$(yq -e eval '.configuration.hetzner.k3s.version' ${CONFIGURATION_FILE})

########################################################################################################################
# ingress-nginx configuration
########################################################################################################################
export INGRESS_DOMAIN=$(yq -e eval '.configuration.ingress.domains[0]' ${CONFIGURATION_FILE})

########################################################################################################################
# wireguard client
########################################################################################################################
if [ ! -d "$HOME/.tmp" ]; then mkdir "$HOME/.tmp"; fi
chmod 700 "$HOME/.tmp" || true
if [ ! -f "${LOCAL_WIREGUARD_FILE}" ]; then
	cat >"${LOCAL_WIREGUARD_FILE}" <<EOF
[Interface]
Address = ${HETZNER_WIREGUARD_CLIENT_IP}
PrivateKey = ${HETZNER_WIREGUARD_CLIENT_PRIVATE_KEY}

[Peer]
PublicKey = ${HETZNER_WIREGUARD_SERVER_PUBLIC_KEY}
Endpoint = ${INGRESS_DOMAIN}:${HETZNER_WIREGUARD_SERVER_PORT}
AllowedIPs = ${HETZNER_WIREGUARD_SERVER_RANGE}, ${HETZNER_PRIVATE_NETWORK_SUBNET}
PersistentKeepalive = 25
EOF
	chmod 600 "${LOCAL_WIREGUARD_FILE}"
fi
wg-quick up "${LOCAL_WIREGUARD_FILE}" || true

########################################################################################################################
# $HOME/.ssh
########################################################################################################################
if [ ! -d "$HOME/.ssh" ]; then mkdir "$HOME/.ssh"; fi
chmod 700 "$HOME/.ssh" || true
set +u
if [ ! -z "${HETZNER_PRIVATE_SSH_KEY}" ]; then
	cat >"$HOME/.ssh/id_rsa" <<EOF
${HETZNER_PRIVATE_SSH_KEY}
EOF
	chmod 600 "$HOME/.ssh/id_rsa"
fi
set -u
set -o pipefail

########################################################################################################################
# known_hosts
########################################################################################################################
if [ ! -f "$HOME/.ssh/known_hosts" ]; then
	# check for server
	export HETZNER_SERVER_EXISTS="true"
	hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" || export HETZNER_SERVER_EXISTS="false"
	if [ "${HETZNER_SERVER_EXISTS}" == "true" ]; then
		# must be done with private-ip via wireguard connection
		HETZNER_NODE_PRIVATE_IP=$(hcloud server list -o json | jq -r ".[] | select(.name == \"${HETZNER_NODE_NAME}\") | .private_net[0].ip")
		echo "adding ${HETZNER_NODE_PRIVATE_IP} to ssh known_hosts ..."
		ssh-keyscan -p 22333 "${HETZNER_NODE_PRIVATE_IP}" 2>/dev/null >>"$HOME/.ssh/known_hosts" || true
	fi
fi

########################################################################################################################
# kubectl config
########################################################################################################################
if [ ! -d "$HOME/.kube" ]; then mkdir "$HOME/.kube"; fi
chmod 700 "$HOME/.kube" || true
set +u
if [ ! -f "${KUBECONFIG}" ]; then
	echo "writing [${KUBECONFIG}] ..."
	hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" 1>/dev/null &&
		hcloud server ssh -p 22333 "${HETZNER_NODE_NAME}" \
			'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${INGRESS_DOMAIN}/g" >"${KUBECONFIG}" || true
fi
chmod 600 "${KUBECONFIG}" || true
set -u
set -o pipefail
