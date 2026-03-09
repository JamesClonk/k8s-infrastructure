#!/bin/bash
set -e
set -u
set -o pipefail

# build
echo "building [headlamp] ..."
pushd chart; helm dependency update .; popd
helm template headlamp --namespace=headlamp "$(pwd)/chart" --values="values.yaml" |
    ytt --ignore-unknown-comments -f - > "../templates/upstream/headlamp.yaml"
