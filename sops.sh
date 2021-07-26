#!/bin/bash
set -e
set -u

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
if [ ! -d "$HOME/.aws" ]; then mkdir "$HOME/.aws"; fi
chmod 700 "$HOME/.aws" || true
set +u
if [ ! -f "$HOME/.aws/config" ]; then
	echo "writing [$HOME/.aws/config] ..."
	cat > "$HOME/.aws/config" << EOF
[profile kms]
region = ${AWS_REGION}
EOF
	chmod 600 "$HOME/.aws/config"
fi
if [ ! -f "$HOME/.aws/credentials" ]; then
	echo "writing [$HOME/.aws/credentials] ..."
	cat > "$HOME/.aws/credentials" << EOF
[kms]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF
	chmod 600 "$HOME/.aws/credentials"
fi
set -u
