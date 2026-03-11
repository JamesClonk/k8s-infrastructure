#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

# render
echo "rendering [grafana] ..."
mkdir -p ../templates/chart-output || true
helm template grafana --namespace=grafana "$(pwd)/chart" --values="values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/chart-output/grafana.yaml"
