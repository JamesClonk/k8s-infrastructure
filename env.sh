#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/.env* 1>/dev/null 2>&1 || true # source any hidden env config files if available

########################################################################################################################
####### environment ####################################################################################################
########################################################################################################################
set +u
if [ -z "${ENVIRONMENT}" ]; then
	if [ "$(git branch --show-current)" == "master" ]; then
		export ENVIRONMENT="production"
	else
		export ENVIRONMENT="development"
	fi
fi
if [ "${ENVIRONMENT}" == "production" ]; then
	export CONFIGURATION_FILE="$(dirname ${BASH_SOURCE[0]})/config/production.yml"
	export SECRETS_FILE="$(dirname ${BASH_SOURCE[0]})/config/production.sops"
else
	export CONFIGURATION_FILE="$(dirname ${BASH_SOURCE[0]})/config/development.yml"
	export SECRETS_FILE="$(dirname ${BASH_SOURCE[0]})/config/development.sops"
fi
set -u
########################################################################################################################


########################################################################################################################
####### kubernetes #####################################################################################################
########################################################################################################################
export KUBECONFIG="$HOME/.kube/k8s-infrastructure"
########################################################################################################################


########################################################################################################################
####### hetzner cloud - k3s ############################################################################################
########################################################################################################################
if [ "${ENVIRONMENT}" == "production" ]; then
	export HCLOUD_TOKEN=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.token' -)

	export HETZNER_SSH_PORT=$(yq -e eval '.configuration.hetzner.ssh.port' ${CONFIGURATION_FILE})
	export HETZNER_SSH_KEY_NAME=$(yq -e eval '.configuration.hetzner.ssh.key_name' ${CONFIGURATION_FILE})
	export HETZNER_PUBLIC_SSH_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.ssh.public_key' -)
	export HETZNER_PRIVATE_SSH_KEY=$(sops -d ${SECRETS_FILE} | yq -e eval '.secrets.hetzner.ssh.private_key' -)

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
fi
########################################################################################################################


########################################################################################################################
####### ingress-nginx ##################################################################################################
########################################################################################################################
export INGRESS_DOMAIN=$(yq -e eval '.configuration.ingress.domains[0]' ${CONFIGURATION_FILE})
########################################################################################################################
