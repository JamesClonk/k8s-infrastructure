#!/bin/bash
set -e
set -u
source $(dirname ${BASH_SOURCE[0]})/sops.sh # prepare sops
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
install_tool "kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.21.10/bin/linux/amd64/kubectl" "24ce60269b1ffe1ca151af8bfd3905c2427ebef620bc9286484121adf29131c0"
install_tool "kapp" "https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.46.0/kapp-linux-amd64" "130f648cd921761b61bb03d7a0f535d1eea26e0b5fc60e2839af73f4ea98e22f"
install_tool "ytt" "https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.40.1/ytt-linux-amd64" "11222665c627b8f0a1443534a3dde3c9b3aac08b322d28e91f0e011e3aeb7df5"
install_tool "vendir" "https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.26.0/vendir-linux-amd64" "98057bf90e09972f156d1c4fbde350e94133bbaf2e25818b007759f5e9c8b197"
install_tool "kbld" "https://github.com/vmware-tanzu/carvel-kbld/releases/download/v0.32.0/kbld-linux-amd64" "de546ac46599e981c20ad74cd2deedf2b0f52458885d00b46b759eddb917351a"
install_tool "imgpkg" "https://github.com/vmware-tanzu/carvel-imgpkg/releases/download/v0.25.0/imgpkg-linux-amd64" "14ce0b48a3a00352cdf0ef263aa98a9bcd90d5ea8634fdf6b88016e2a08f09d1"
install_tool "yq" "https://github.com/mikefarah/yq/releases/download/v4.21.1/yq_linux_amd64" "50778261e24c70545a3ff8624df8b67baaff11f759e6e8b2e4c9c781df7ea8dc"
install_tool "jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44"
install_tool "kind" "https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64" "949f81b3c30ca03a3d4effdecda04f100fa3edc07a28b19400f72ede7c5f0491"
install_tool_from_tarball "cmctl" "cmctl" "https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cmctl-linux-amd64.tar.gz" "6e22fda56e0fa62cb3fab9340be23ba3fa0da341e737006a9552abdcc80c789e"
install_tool_from_tarball "hcloud" "hcloud" "https://github.com/hetznercloud/cli/releases/download/v1.23.0/hcloud-linux-amd64.tar.gz" "500320950002dd9d24eeb47c66b3136c5318fa08c5f73e1b981a16a4dc320cad"
install_tool_from_tarball "linux-amd64/helm" "helm" "https://get.helm.sh/helm-v3.8.0-linux-amd64.tar.gz" "f197057230be75a9db85225c2eaf49f65918bffd5e9e2174a88c41cd5623ea50"
install_tool_from_tarball "k9s" "k9s" "https://github.com/derailed/k9s/releases/download/v0.23.3/k9s_Linux_x86_64.tar.gz" "51eb79a779f372961168b62d584728e478d4c8a447986c2c64ef3892beb0e53e"

# git config
git config --local core.hooksPath .githooks/
git config --local diff.sopsdiffer.textconv "sops -d"

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
if [ "${ENVIRONMENT}" == "production" ]; then
	if [ ! -f "$HOME/.ssh/known_hosts" ]; then
		hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" 1>/dev/null \
			&& ssh-keyscan -p "${HETZNER_SSH_PORT}" "$(hcloud server ip "${HETZNER_NODE_NAME}")" 2>/dev/null >> "$HOME/.ssh/known_hosts" || true
		chmod 600 "$HOME/.ssh/known_hosts" || true
	fi
fi

# kubectl config
$(dirname ${BASH_SOURCE[0]})/kubeconfig.sh # setup kubeconfig
