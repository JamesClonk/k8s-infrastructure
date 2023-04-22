#!/bin/bash
set -e
set -u
set -o pipefail

# build
echo "building [prometheus] ..."
pushd chart; helm dependency update .; popd
helm template prometheus --namespace=prometheus "$(pwd)/chart" --values="values.yml" |
    ytt --ignore-unknown-comments -f - > "../templates/upstream/prometheus.yml"
