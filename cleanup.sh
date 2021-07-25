#!/bin/bash
set -e
set -u
source $(dirname ${BASH_SOURCE[0]})/env.sh # source env configuration files

# $HOME/.ssh
echo "removing [$HOME/.ssh/id_rsa] ..."
rm -f "$HOME/.ssh/id_rsa" || true

# aws config
echo "removing [$HOME/.aws/config] ..."
rm -f "$HOME/.aws/config" || true
echo "removing [$HOME/.aws/credentials] ..."
rm -f "$HOME/.aws/credentials" || true

# kubectl config
echo "removing [${KUBECONFIG}] ..."
rm -f "${KUBECONFIG}" || true
