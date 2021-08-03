#!/bin/bash
set -e
set -u
source ../setup.sh

# delete
kind delete cluster --name kind || true
