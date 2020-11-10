# k8s-infrastructure
Create your own personal Kubernetes infrastructure, the quick and easy way

## Quick start

```
## get this repository here
git clone https://github.com/JamesClonk/k8s-infrastructure
cd k8s-infrastructure

# adjust the following variables:
# HCLOUD_TOKEN, HETZNER_PUBLIC_SSH_KEY
# INGRESS_DOMAIN, INGRESS_BASIC_AUTH_USERNAME, INGRESS_BASIC_AUTH_PASSWORD
# LETS_ENCRYPT_EMAIL_ADDRESS
vi configuration.env.sh`

# provision Kubernetes on Hetzner Cloud, install basic tools and software:
# ingress-nginx, cert-manager, dashboard, prometheus, loki, grafana
./deploy.sh
```

## What is this?

## Installation

## Configuration

### Tools used

- #### https://k3s.io/
  - ###### https://github.com/rancher/k3s

- #### https://www.hetzner.com/cloud
  - ###### https://github.com/hetznercloud/cli

- #### https://carvel.dev (formerly https://k14s.io)
  - ###### https://get-kapp.io
    Deploy and view groups of Kubernetes resources as applications
  - ###### https://get-ytt.io
    Template and overlay Kubernetes configuration via YAML structures
  - ###### https://github.com/k14s/vendir
    Declaratively state what files should be in a directory
  - ###### https://get-kbld.io
    Seamlessly incorporates image building, pushing, and resolution into deployment workflows
  - ###### https://github.com/k14s/kapp-controller
    Kubernetes controller for Kapp, provides App CRDs

- #### https://github.com/derailed/k9s
  Terminal UI to interact with your Kubernetes clusters
