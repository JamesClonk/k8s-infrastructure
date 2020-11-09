#!/bin/bash
set -e
set -u

# build
echo "building [loki] ..."
pushd charts/loki; helm dependency update .; popd
helm template loki --namespace=loki "$(pwd)/charts/loki"  --values="loki.values.yml" |
    ytt --ignore-unknown-comments -f - > "../templates/upstream/loki.yml"

echo "building [promtail] ..."
pushd charts/promtail; helm dependency update .; popd
helm template promtail --namespace=loki "$(pwd)/charts/promtail"  --values="promtail.values.yml" |
    ytt --ignore-unknown-comments -f - > "../templates/upstream/promtail.yml"
