#!/bin/bash
set -e
set -u
source $(dirname ${BASH_SOURCE[0]})/.env* 1>/dev/null 2>&1 || true # source any hidden env config files if available

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

# $HOME/bin
if [ ! -d "$HOME/bin" ]; then mkdir "$HOME/bin"; fi
export PATH="$HOME/bin:$PATH"

# install tools
install_tool "sops" "https://github.com/mozilla/sops/releases/download/v3.7.1/sops-v3.7.1.linux" "185348fd77fc160d5bdf3cd20ecbc796163504fd3df196d7cb29000773657b74"
install_tool "yq" "https://github.com/mikefarah/yq/releases/download/v4.11.2/yq_linux_amd64" "6b891fd5bb13820b2f6c1027b613220a690ce0ef4fc2b6c76ec5f643d5535e61"

# aws config
set +u
if [ -z "${AWS_REGION}" ]; then
	echo "AWS_REGION must be set!"
	exit 1
fi
if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
	echo "AWS_ACCESS_KEY_ID must be set!"
	exit 1
fi
if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
	echo "AWS_SECRET_ACCESS_KEY must be set!"
	exit 1
fi
set -u
