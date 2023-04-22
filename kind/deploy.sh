#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# deploy
echo "deploying [kind] ..."
kind create cluster --name kind --config cluster.yml || true
kubectl config use-context kind-kind
kubectl cluster-info
