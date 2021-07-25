#!/bin/bash
set -e
set -u
source $(dirname ${BASH_SOURCE[0]})/env.sh # source env configuration files

function basic_auth() {
	local -r username="$1"; shift
	local -r password="$1"; shift
	echo "${username}:$(openssl passwd -apr1 \"${password}\")"
}

function retry() {
	local -r -i max_attempts="$1"; shift
	local -r -i sleep_time="$1"; shift
	local -i attempt_num=1
	until "$@"; do
		if (( attempt_num == max_attempts ))
	then
		echo "#$attempt_num failures!"
		exit 1
	else
		echo "#$(( attempt_num++ )): trying again in $sleep_time seconds ..."
		sleep $sleep_time
		fi
	done
}

function install_tool {
	local -r tool_name="$1"; shift
	local -r tool_url="$1"; shift
	local -r tool_checksum="$1"; shift
	if [ ! -f "$HOME/bin/${tool_name}" ]; then
		echo "downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}"
		chmod +x "$HOME/bin/${tool_name}"
	fi
	sha256sum "$HOME/bin/${tool_name}" | grep "${tool_checksum}" >/dev/null || (echo "checksum failed for [${tool_name}]" && rm -f "$HOME/bin/${tool_name}" && exit 1)
}

function install_tool_from_tarball {
	local -r tool_path="$1"; shift
	local -r tool_name="$1"; shift
	local -r tool_url="$1"; shift
	local -r tool_checksum="$1"; shift
	if [ ! -f "$HOME/bin/${tool_name}" ]; then
		echo "downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}.tgz"
		echo "unpacking [${tool_name}.tgz] ..."
		STRIP_COMPONENTS=$(echo "${tool_path}" | awk -F"/" '{print NF-1}')
		tar -xvzf "$HOME/bin/${tool_name}.tgz" --strip-components=${STRIP_COMPONENTS} -C "$HOME/bin/" "${tool_path}"
		chmod +x "$HOME/bin/${tool_name}"
		rm -f "$HOME/bin/${tool_name}.tgz"
	fi
	sha256sum "$HOME/bin/${tool_name}" | grep "${tool_checksum}" >/dev/null || (echo "checksum failed for [${tool_name}]" && rm -f "$HOME/bin/${tool_name}" && exit 1)
}

# $HOME/bin
if [ ! -d "$HOME/bin" ]; then mkdir "$HOME/bin"; fi
export PATH="$HOME/bin:$PATH"

# install tools
install_tool "kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.19.13/bin/linux/amd64/kubectl" "275a97f2c825e8148b46b5b7eb62c1c76bdbadcca67f5e81f19a5985078cc185"
install_tool "kapp" "https://github.com/k14s/kapp/releases/download/v0.35.0/kapp-linux-amd64" "0f9d4daa8c833a8e245362c77e72f4ed06d4f0a12eed6c09813c87a992201676"
install_tool "ytt" "https://github.com/k14s/ytt/releases/download/v0.31.0/ytt-linux-amd64" "32e7cdc38202b49fe673442bd22cb2b130e13f0f05ce724222a06522d7618395"
install_tool "vendir" "https://github.com/k14s/vendir/releases/download/v0.16.0/vendir-linux-amd64" "05cede475c2b947772a9fe552380927054d48158959c530122a150a93bf542dd"
install_tool "kbld" "https://github.com/k14s/kbld/releases/download/v0.29.0/kbld-linux-amd64" "28492a398854e8fec7dd9537243b07af7f43e6598e1e4557312f5481f6840499"
install_tool "sops" "https://github.com/mozilla/sops/releases/download/v3.7.1/sops-v3.7.1.linux" "185348fd77fc160d5bdf3cd20ecbc796163504fd3df196d7cb29000773657b74"
install_tool_from_tarball "hcloud" "hcloud" "https://github.com/hetznercloud/cli/releases/download/v1.23.0/hcloud-linux-amd64.tar.gz" "500320950002dd9d24eeb47c66b3136c5318fa08c5f73e1b981a16a4dc320cad"
install_tool_from_tarball "linux-amd64/helm" "helm" "https://get.helm.sh/helm-v3.4.0-linux-amd64.tar.gz" "58550525963821a227307590627d0c266414e4c56247a5c11559e4abd990b0ae"
install_tool_from_tarball "k9s" "k9s" "https://github.com/derailed/k9s/releases/download/v0.23.3/k9s_Linux_x86_64.tar.gz" "51eb79a779f372961168b62d584728e478d4c8a447986c2c64ef3892beb0e53e"

# $HOME/.ssh
if [ ! -d "$HOME/.ssh" ]; then mkdir "$HOME/.ssh"; fi
chmod 700 "$HOME/.ssh" || true
set +u
if [ ! -z "${HETZNER_PRIVATE_SSH_KEY}" ]; then
	cat > "$HOME/.ssh/id_rsa" << EOF
${HETZNER_PRIVATE_SSH_KEY}
EOF
	chmod 600 "$HOME/.ssh/id_rsa"
fi
set -u
# known_hosts
if [ ! -f "$HOME/.ssh/known_hosts" ]; then
	hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" 1>/dev/null \
		&& ssh-keyscan -p "${HETZNER_SSH_PORT}" "$(hcloud server ip "${HETZNER_NODE_NAME}")" 2>/dev/null >> "$HOME/.ssh/known_hosts" || true
	chmod 600 "$HOME/.ssh/known_hosts" || true
fi

# kubectl config
if [ ! -d "$HOME/.kube" ]; then mkdir "$HOME/.kube"; fi
chmod 700 "$HOME/.kube" || true
if [ ! -f "${KUBECONFIG}" ]; then
	hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" 1>/dev/null \
		&& hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
		'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${INGRESS_DOMAIN}/g" > "${KUBECONFIG}" || true
	chmod 600 "${KUBECONFIG}" || true
fi
