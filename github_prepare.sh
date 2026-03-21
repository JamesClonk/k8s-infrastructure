#!/bin/bash
set -e
set -u
set -o pipefail

# install wireguard
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq wireguard-tools net-tools

# initial render to get the ball rolling, to be able to source setup.sh ...
# install sops and plato
if [ ! -d "$HOME/bin" ]; then mkdir "$HOME/bin"; fi
export PATH="$HOME/bin:$PATH"
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
install_tool "sops" "https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64" "775f1384d55decfad228e7196a3f683791914f92a473f78fc47700531c29dfef"
install_tool_from_tarball "plato" "plato" "https://github.com/JamesClonk/plato/releases/download/v1.2.0/plato_1.2.0_linux_x86_64.tar.gz" "06df874fd408c9f59dfc46cafe92bdb46ecb1095392650988fade58f37006d7b"

# render
plato render
