#!/bin/bash
set -e
set -u

# deploy
echo "deploying [monitoring] ..."

deployments=(
	"kube-state-metrics"
	"prometheus"
	"loki"
	"grafana"
)
for deployment in ${deployments[@]}; do
	pushd $deployment
	./deploy.sh
	popd
done

if [ "${PROMETHEUS_ALERTMANAGER_TEAMS_WEBHOOK_ENABLED}" == "true" ]; then
	pushd "prometheus-msteams"
	./deploy.sh
	popd
fi
