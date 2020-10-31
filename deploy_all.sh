#!/bin/bash
set -e
set -u

deployments=(
	# setup cluster on hetzner cloud
	"k3s"

	# we need some fancy routing here..
	"ingress-nginx"
)

# deploy it all, all of it!
for deployment in ${deployments[@]}; do
	pushd $deployment
	./deploy.sh
	popd
	echo -e "\n\n"
done
