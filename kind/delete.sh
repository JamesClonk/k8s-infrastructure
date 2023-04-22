#!/bin/bash
set -e
set -u
set -o pipefail
source ../setup.sh

# delete
kind delete cluster --name kind || true
