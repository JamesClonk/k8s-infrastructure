#!/bin/bash
set -e
source ../setup.sh

# deploy
echo "deploying [ingress-nginx] ..."
ytt --ignore-unknown-comments -f templates | kbld -f - -f image.lock.yml | kapp -y deploy -a ingress-nginx -c -f -
kapp -y app-change garbage-collect -a ingress-nginx --max 5
echo "done!"
