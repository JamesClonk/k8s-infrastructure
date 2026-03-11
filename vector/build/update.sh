#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

# update
echo "updating [vector] charts ..."
pushd chart; helm dependency update .; popd
