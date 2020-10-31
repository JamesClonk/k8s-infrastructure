#!/bin/bash
set -e

function install_tool {
	TOOL_NAME=$1
	TOOL_URL=$2
	if [ ! -f "$HOME/bin/${TOOL_NAME}" ]; then
		echo "downloading [${TOOL_NAME}] ..."
		wget "${TOOL_URL}" -O "$HOME/bin/${TOOL_NAME}"
		chmod +x "$HOME/bin/${TOOL_NAME}"
	fi
}

function install_tool_from_tarball {
	TOOL_NAME=$1
	TOOL_URL=$2
	if [ ! -f "$HOME/bin/${TOOL_NAME}" ]; then
		echo "downloading [${TOOL_NAME}] ..."
		wget "${TOOL_URL}" -O "$HOME/bin/${TOOL_NAME}.tgz"
		echo "unpacking [${TOOL_NAME}.tgz] ..."
		tar -xvzf "$HOME/bin/${TOOL_NAME}.tgz" -C "$HOME/bin/" "${TOOL_NAME}"
		chmod +x "$HOME/bin/${TOOL_NAME}"
		rm -f "$HOME/bin/${TOOL_NAME}.tgz"
	fi
}

# $HOME/bin
if [ ! -d "$HOME/bin" ]; then mkdir "$HOME/bin"; fi
export PATH="$HOME/bin:$PATH"

# install tools
install_tool "kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.19.3/bin/linux/amd64/kubectl"
install_tool "envsubst" "https://github.com/JamesClonk/envsubst/releases/download/v1.1.1/envsubst_1.1.1_Linux-64bit"
install_tool "kapp" "https://github.com/k14s/kapp/releases/download/v0.34.0/kapp-linux-amd64"
install_tool "ytt" "https://github.com/k14s/ytt/releases/download/v0.30.0/ytt-linux-amd64"
install_tool "vendir" "https://github.com/k14s/vendir/releases/download/v0.11.0/vendir-linux-amd64"
install_tool "kbld" "https://github.com/k14s/kbld/releases/download/v0.27.0/kbld-linux-amd64"
install_tool "kwt" "https://github.com/k14s/kwt/releases/download/v0.0.6/kwt-linux-amd64"
install_tool_from_tarball "hcloud" "https://github.com/hetznercloud/cli/releases/download/v1.19.1/hcloud-linux-amd64.tar.gz"
install_tool_from_tarball "k9s" "https://github.com/derailed/k9s/releases/download/v0.23.3/k9s_Linux_x86_64.tar.gz"

# vars
export KUBE_APP_NAME=$(basename "$PWD")

# disable diff on CI
export KAPP_DIFF="--diff-changes"
if [ ! -z "${CI}" ]; then
	export KAPP_DIFF=""
fi
if [ ! -z "${CIRCLECI}" ]; then
	export KAPP_DIFF=""
fi
if [ ! -z "${CIRCLE_JOB}" ]; then
	export KAPP_DIFF=""
fi
if [ ! -z "${TRAVIS}" ]; then
	export KAPP_DIFF=""
fi

# which env are we targetting?
if [ -z "${KUBE_ENVIRONMENT}" ]; then
	export KUBE_ENVIRONMENT=$(kubectl config current-context)
	if [ "${KUBE_ENVIRONMENT}" == "minikube" ]; then
		export KUBE_ENVIRONMENT="local"
	fi
	if [ "${KUBE_ENVIRONMENT}" == "microk8s" ]; then
		export KUBE_ENVIRONMENT="local"
	fi
	if [ "${KUBE_ENVIRONMENT}" == "kind" ]; then
		export KUBE_ENVIRONMENT="local"
	fi
	if [ "${KUBE_ENVIRONMENT}" == "scaleway" ]; then
		export KUBE_ENVIRONMENT="prod"
	fi
	if [ "${KUBE_ENVIRONMENT}" == "hetzner" ]; then
		export KUBE_ENVIRONMENT="prod"
	fi
	if [ "${KUBE_ENVIRONMENT}" == "production" ]; then
		export KUBE_ENVIRONMENT="prod"
	fi
fi

# what's the domain for that env?
export KUBE_DOMAIN="127.0.0.1.xip.io"
if [ "${KUBE_ENVIRONMENT}" == "local" ]; then
	export KUBE_DOMAIN="127.0.0.1.xip.io"
fi
if [ "${KUBE_ENVIRONMENT}" == "test" ]; then
	export KUBE_DOMAIN="test.jamesclonk.io"
fi
if [ "${KUBE_ENVIRONMENT}" == "prod" ]; then
	export KUBE_DOMAIN="jamesclonk.io"
fi
