#!/bin/bash
set -e
set -u

deployments=(
	# setup cluster on hetzner cloud
	"hetzner-k3s"

	# we need some fancy ingress routing
	"ingress-nginx"

	# and automatic let's encrypt certificate management
	"cert-manager"

	# it also never hurts to have a dashboard!
	"kubernetes-dashboard"
)

# deploy it all, all of it!
for deployment in ${deployments[@]}; do
	pushd $deployment
	./deploy.sh
	popd
	echo -e "\n\n"
done
