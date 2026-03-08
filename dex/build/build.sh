#!/bin/bash
set -e
set -u
set -o pipefail

# build
echo "building [dex] ..."
pushd chart; helm dependency update .; popd
helm template dex --namespace=dex "$(pwd)/chart" --values="values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/upstream/dex.yaml"
