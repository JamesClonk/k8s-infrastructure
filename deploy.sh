#!/bin/bash
set -e
set -u
source $(dirname ${BASH_SOURCE[0]})/setup.sh

if [ "${ENVIRONMENT}" == "development" ]; then
	deployments=(
	# setup a local kind cluster
	"kind"

	# add metrics-server to our local kind cluster, it feels lonely without it..
	"metrics-server"
)
else
	deployments=(
	# setup cluster on hetzner cloud
	"hetzner-k3s"

	# we want to use some hetzner cloud volumes
	"hcloud-csi"
)
fi

deployments+=(
	# let's own the kube-system namespace
	"kube-system"

	# we need some fancy ingress routing
	"ingress-nginx"

	# and want to use github oauth
	"oauth2-proxy"

	# and automatic let's encrypt certificate management
	"cert-manager"

	# it also never hurts to have a dashboard!
	"kubernetes-dashboard"

	# metrics, monitoring, alerting, logs, what would we do without those?
	"monitoring"

	# we can always use a good database..
	"postgres"
)

# deploy it all, all of it!
for deployment in ${deployments[@]}; do
	pushd $deployment
	./deploy.sh
	popd
	echo -e "\n\n"
done
kapp list
echo " "
