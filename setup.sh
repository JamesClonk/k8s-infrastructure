#!/bin/bash
set -e
set -u
source $(dirname ${BASH_SOURCE[0]})/.env* 1>/dev/null 2>&1 || true # source any optional/hidden env config files first if available
source $(dirname ${BASH_SOURCE[0]})/configuration.env.sh # source main configuration file

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
		return 1
	else
		echo "#$(( attempt_num++ )): trying again in $sleep_time seconds ..."
		sleep $sleep_time
		fi
	done
}

function install_tool {
	local -r tool_name="$1"; shift
	local -r tool_url="$1"; shift
	if [ ! -f "$HOME/bin/${tool_name}" ]; then
		echo "downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}"
		chmod +x "$HOME/bin/${tool_name}"
	fi
}

function install_tool_from_tarball {
	local -r tool_path="$1"; shift
	local -r tool_name="$1"; shift
	local -r tool_url="$1"; shift
	if [ ! -f "$HOME/bin/${tool_name}" ]; then
		echo "downloading [${tool_name}] ..."
		wget -q "${tool_url}" -O "$HOME/bin/${tool_name}.tgz"
		echo "unpacking [${tool_name}.tgz] ..."
		STRIP_COMPONENTS=$(echo "${tool_path}" | awk -F"/" '{print NF-1}')
		tar -xvzf "$HOME/bin/${tool_name}.tgz" --strip-components=${STRIP_COMPONENTS} -C "$HOME/bin/" "${tool_path}"
		chmod +x "$HOME/bin/${tool_name}"
		rm -f "$HOME/bin/${tool_name}.tgz"
	fi
}

# $HOME/bin
if [ ! -d "$HOME/bin" ]; then mkdir "$HOME/bin"; fi
export PATH="$HOME/bin:$PATH"

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

# kubectl config
if [ ! -d "$HOME/.kube" ]; then mkdir "$HOME/.kube"; fi
chmod 700 "$HOME/.kube" || true
set +u
if [ -n "${KUBECONFIG_DATA}" ]; then
	if [ "${KUBECONFIG_DATA}" != "NONE" ]; then
		if [ ! -f "${KUBECONFIG}" ]; then
			echo "writing [${KUBECONFIG}] ..."
			cat > "${KUBECONFIG}" << EOF
${KUBECONFIG_DATA}
EOF
			chmod 600 "${KUBECONFIG}"
		fi
	fi
fi
set -u

# install tools
install_tool "kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.19.3/bin/linux/amd64/kubectl"
install_tool "envsubst" "https://github.com/JamesClonk/envsubst/releases/download/v1.1.1/envsubst_1.1.1_Linux-64bit"
install_tool "kapp" "https://github.com/k14s/kapp/releases/download/v0.34.0/kapp-linux-amd64"
install_tool "ytt" "https://github.com/k14s/ytt/releases/download/v0.30.0/ytt-linux-amd64"
install_tool "vendir" "https://github.com/k14s/vendir/releases/download/v0.14.0/vendir-linux-amd64"
install_tool "kbld" "https://github.com/k14s/kbld/releases/download/v0.27.0/kbld-linux-amd64"
install_tool_from_tarball "hcloud" "hcloud" "https://github.com/hetznercloud/cli/releases/download/v1.19.1/hcloud-linux-amd64.tar.gz"
install_tool_from_tarball "linux-amd64/helm" "helm" "https://get.helm.sh/helm-v3.4.0-linux-amd64.tar.gz"
install_tool_from_tarball "k9s" "k9s" "https://github.com/derailed/k9s/releases/download/v0.23.3/k9s_Linux_x86_64.tar.gz"
