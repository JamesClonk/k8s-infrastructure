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
####### firewall #######################################################################################################
########################################################################################################################
if [ "{{{ .hetzner.firewall.enabled }}}" == "true" ]; then
	echo "checking for firewall [{{{ .hetzner.firewall.name }}}] ..."
	hcloud firewall list -o noheader | grep "{{{ .hetzner.firewall.name }}}" 1>/dev/null ||
		(echo "creating {{{ .hetzner.firewall.name }}} ..." &&
			cat firewall_rules.json | hcloud firewall create --name "{{{ .hetzner.firewall.name }}}" --rules-file - &&
			sleep 30)
	# wait half a minute for firewall to be ready for sure

	# setup firewall
	echo "setting rules for firewall ..."
	cat firewall_rules.json | hcloud firewall replace-rules "{{{ .hetzner.firewall.name }}}" --rules-file - 1>/dev/null

	echo "applying firewall to server [{{{ .hetzner.node.name }}}] ..."
	hcloud firewall apply-to-resource "{{{ .hetzner.firewall.name }}}" --server "{{{ .hetzner.node.name }}}" --type server 1>/dev/null || true
	echo " "
fi
