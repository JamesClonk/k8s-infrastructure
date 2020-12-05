# k8s-infrastructure
Create your own personal Kubernetes infrastructure, the quick and easy way

## Quick start

```bash
## get this repository here
git clone https://github.com/JamesClonk/k8s-infrastructure
cd k8s-infrastructure

# adjust at minimum the following variables:
# HCLOUD_TOKEN, HETZNER_PUBLIC_SSH_KEY
# INGRESS_DOMAIN, INGRESS_BASIC_AUTH_USERNAME, INGRESS_BASIC_AUTH_PASSWORD
# LETS_ENCRYPT_EMAIL_ADDRESS
vi configuration.env.sh

# provision Kubernetes on Hetzner Cloud with CSI driver for persistent volumes
# and install these basic tools and software:
# ingress-nginx, cert-manager, dashboard, prometheus, loki, grafana
./deploy.sh
```

## What is this?

## Installation

## Configuration

## Architecture

![Kubernetes](docs/architecture.png)

### Thoughts & considerations

#### Why not using operators?

Well, this is meant to be used for a *single-user* Kubernetes cluster, whether with only a one or multiple nodes, self-deployed or managed.  While operators are certainly cool pieces of software they don't really make much sense for a single-user scenario, hence I saw no reason to use the prometheus, grafana and postgres operators for those parts of this Kubernetes-infrastructure-as-code project.

#### Why using simple basic-auth for all ingresses?

I was considering and experimenting with using [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) and [authelia](https://github.com/authelia/authelia), but ultimately made the same decision as with regards to using operators. It simply doesn't make much sense for a single-user Kubernetes cluster, the engineering and operational overhead was not worth it. All I needed are static username+password credentials for securing my applications.

My recommendation would be to use one of these two if you have more requirements than me:
- https://github.com/oauth2-proxy/oauth2-proxy (Simple oauth2 proxy to be used with GitHub for example)
- https://github.com/authelia/authelia (Allows sophisticated auth configuration, 2FA, etc.)

Both can be configured easily to work well together with *ingress-nginx*.

### Deployments

- #### [K3s](https://k3s.io)
  - ###### https://github.com/rancher/k3s
    An easy to install, lightweight, fully compliant Kubernetes distribution packaged as a single binary

- #### [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx)
  - ###### https://github.com/kubernetes/ingress-nginx
    An Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer

- #### [cert-manager](https://cert-manager.io)
  - ###### https://github.com/jetstack/cert-manager
    Automatic certificate management on top of Kubernetes, using [Let's Encrypt](https://letsencrypt.org)

- #### [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard)
  - ###### https://github.com/kubernetes/dashboard
    General-purpose web UI for Kubernetes clusters

- #### [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
  - ###### https://github.com/kubernetes/kube-state-metrics
    Add-on agent to generate and expose cluster-level metrics

- #### [Prometheus](https://prometheus.io)
  - ###### https://github.com/prometheus
    Monitoring & alerting system, and time series database for metrics

- #### [Loki](https://grafana.com/oss/loki)
  - ###### https://github.com/grafana/loki
    A horizontally-scalable, highly-available, multi-tenant log aggregation system

- #### [Grafana](https://grafana.com/grafana)
  - ###### https://github.com/grafana/grafana
    Monitoring and metric analytics & dashboards for Prometheus and Loki

- #### [PostgreSQL](https://www.postgresql.org)
  - ###### https://www.postgresql.org/docs
    The world's most advanced open source relational database

### Tools used

- #### [Hetzner Cloud](https://www.hetzner.com/cloud)
  - ###### https://github.com/hetznercloud/cli
    Command-line interface for interacting with Hetzner Cloud

- #### [Carvel](https://carvel.dev) (formerly https://k14s.io)
  - ###### [kapp](https://get-kapp.io)
    Deploy and view groups of Kubernetes resources as applications
  - ###### [ytt](https://get-ytt.io)
    Template and overlay Kubernetes configuration via YAML structures
  - ###### [vendir](https://github.com/vmware-tanzu/carvel-vendir)
    Declaratively state what files should be in a directory
  - ###### [kbld](https://get-kbld.io)
    Seamlessly incorporates image building, pushing, and resolution into deployment workflows
  - ###### [kapp-controller](https://github.com/vmware-tanzu/carvel-kapp-controller)
    Kubernetes controller for Kapp, provides App CRDs

- #### [k9s](https://k9scli.io)
  - ###### https://github.com/derailed/k9s
    Terminal UI to interact with your Kubernetes clusters
