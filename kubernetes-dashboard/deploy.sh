#!/bin/bash
set -e
set -u
source ../setup.sh

# deploy
echo "deploying [kubernetes-dashboard] ..."
sops -d ${SECRETS_FILE} |
	ytt --ignore-unknown-comments -f templates -f values.yml -f ${CONFIGURATION_FILE} -f - --data-value-file dashboard.kubeconfig="${KUBECONFIG}" |
	kbld -f - -f image.lock.yml |
	kapp deploy -a kubernetes-dashboard -c -y -f -
kapp app-change garbage-collect -a kubernetes-dashboard --max 5 -y

if [ "${ENVIRONMENT}" == "development" ]; then
	# get a cluster-admin service account token for user auth
	kubectl -n kubernetes-dashboard create serviceaccount dashboard-admin || true
	kubectl -n kubernetes-dashboard create clusterrolebinding dashboard-admin \
		--clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin || true
	TOKEN=$(kubectl -n kubernetes-dashboard describe secret dashboard-admin | awk '$1=="token:"{print $2}')
	kubectl config set-credentials kind-kind --token="${TOKEN}"
fi
