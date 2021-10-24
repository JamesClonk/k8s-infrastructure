#!/bin/bash
set -e
set -u

helm inspect values "$(pwd)/chart" > oauth2-proxy.values
