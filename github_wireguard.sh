#!/bin/bash
set -e
set -u
set -o pipefail

# install wireguard
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq wireguard-tools net-tools
