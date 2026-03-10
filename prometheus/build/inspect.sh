#!/bin/bash
set -e
set -u
set -o pipefail

helm inspect values "$(pwd)/chart" > prometheus.values
