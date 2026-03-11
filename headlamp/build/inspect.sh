#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

helm inspect values "$(pwd)/chart" > headlamp.values
