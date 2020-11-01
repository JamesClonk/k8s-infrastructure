#!/bin/bash
set -e
set -u
source configuration.env

deployments=(
	# setup cluster on hetzner cloud
	"k3s"

	# now we need some fancy ingress routing
	"ingress-nginx"

	# and it never hurts to have a dashboard!
	"kubernetes-dashboard"
)

# deploy it all, all of it!
for deployment in ${deployments[@]}; do
	pushd $deployment
	./deploy.sh
	popd
	echo -e "\n\n"
done
