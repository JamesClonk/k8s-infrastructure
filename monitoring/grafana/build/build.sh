#!/bin/bash
set -e
set -u

# build
echo "building [grafana] ..."
pushd chart; helm dependency update .; popd
helm template grafana --namespace=grafana "$(pwd)/chart" --values="values.yml" |
    ytt --ignore-unknown-comments -f - > "../templates/upstream/grafana.yml"
