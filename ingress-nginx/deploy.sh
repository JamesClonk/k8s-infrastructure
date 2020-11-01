#!/bin/bash
set -e
source ../setup.sh

# deploy
echo "deploying [ingress-nginx] ..."
ytt --ignore-unknown-comments -f templates -f values.yml | kapp -y deploy -a ingress-nginx -c -f -
kapp -y app-change garbage-collect -a ingress-nginx --max 5
echo "done!"
