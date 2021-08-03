#!/bin/bash
set -e
set -u

# kubectl config
if [ ! -d "$HOME/.kube" ]; then mkdir "$HOME/.kube"; fi
chmod 700 "$HOME/.kube" || true
set +u
if [ ! -f "${KUBECONFIG}" ]; then
	if [ "${ENVIRONMENT}" == "production" ]; then
		hcloud server list -o noheader | grep "${HETZNER_NODE_NAME}" 1>/dev/null \
			&& hcloud server ssh -p "${HETZNER_SSH_PORT}" "${HETZNER_NODE_NAME}" \
			'cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/${INGRESS_DOMAIN}/g" > "${KUBECONFIG}" || true
	else
		kind get kubeconfig --name kind > "${KUBECONFIG}" || true
	fi
	chmod 600 "${KUBECONFIG}" || true
fi
set -u
