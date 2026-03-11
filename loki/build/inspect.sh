#!/bin/bash
set -e
set -u
set -o pipefail
cd $(dirname ${BASH_SOURCE[0]})

helm inspect values "$(pwd)/charts/loki" > loki.values
