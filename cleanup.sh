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
export LOCAL_WIREGUARD_FILE="$HOME/.hetzner0.conf"

########################################################################################################################
# wireguard
########################################################################################################################
echo "taking down wireguard with [${LOCAL_WIREGUARD_FILE}] ..."
wg-quick down "${LOCAL_WIREGUARD_FILE}" || true
echo "removing [${LOCAL_WIREGUARD_FILE}] ..."
rm -f "${LOCAL_WIREGUARD_FILE}" || true

########################################################################################################################
# $HOME/.ssh
########################################################################################################################
echo "removing [$HOME/.ssh/id_rsa] ..."
rm -f "$HOME/.ssh/id_rsa" || true

########################################################################################################################
# kubectl config
########################################################################################################################
echo "removing [${KUBECONFIG}] ..."
rm -f "${KUBECONFIG}" || true
