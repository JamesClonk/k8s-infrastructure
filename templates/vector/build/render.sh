#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

# render
echo "rendering [vector] ..."
mkdir -p ../templates/chart-output || true
helm template vector --namespace=vector "$(pwd)/chart" --values="values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/chart-output/vector.yaml"
