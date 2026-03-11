#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

# render
echo "rendering [dex] ..."
mkdir -p ../templates/chart-output || true
helm template dex --namespace=dex "$(pwd)/charts/dex" --values="dex.values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/chart-output/dex.yaml"
