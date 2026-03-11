#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

# render
echo "rendering [headlamp] ..."
mkdir -p ../templates/chart-output || true
helm template headlamp --namespace=loki "$(pwd)/charts/headlamp" --values="headlamp.values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/chart-output/headlamp.yaml"
