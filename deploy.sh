#!/bin/bash
set -e
set -u

deployments=(
	# setup cluster on hetzner cloud
	"hetzner-k3s"

	# let's own the kube-system namespace
	"kube-system"

	# we need some fancy ingress routing
	"ingress-nginx"

	# and automatic let's encrypt certificate management
	# "cert-manager" - TODO: no cert-manager for now, we'll enabled it once everything is prod ready

	# it also never hurts to have a dashboard!
	"kubernetes-dashboard"

	# metrics, monitoring, alerting, logs, what would we do without those?
	"monitoring"
)

# deploy it all, all of it!
for deployment in ${deployments[@]}; do
	pushd $deployment
	./deploy.sh
	popd
	echo -e "\n\n"
done
