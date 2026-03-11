#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

# render
echo "rendering [prometheus] ..."
mkdir -p ../templates/chart-output || true
helm template prometheus --namespace=prometheus "$(pwd)/chart" --values="values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/chart-output/prometheus.yaml"
