#!/bin/bash
set -e
set -u
set -o pipefail

# build
echo "building [oauth2-proxy] ..."
pushd chart; helm dependency update .; popd
helm template oauth2-proxy --namespace=oauth2-proxy "$(pwd)/chart" --values="values.yml" |
    ytt --ignore-unknown-comments -f - > "../templates/upstream/oauth2-proxy.yml"
