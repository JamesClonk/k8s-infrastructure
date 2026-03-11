#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

# render
echo "rendering [loki] ..."
mkdir -p ../templates/chart-output || true
helm template loki --namespace=loki "$(pwd)/charts/loki" --values="loki.values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/chart-output/loki.yaml"
