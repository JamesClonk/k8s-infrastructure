#!/bin/bash
set -e
set -u

helm inspect values "$(pwd)/chart" > prometheus.values
