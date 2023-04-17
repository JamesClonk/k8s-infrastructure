# k8s-infrastructure 🐳

[![Build](https://img.shields.io/github/actions/workflow/status/JamesClonk/k8s-infrastructure/production.yml?branch=master&label=Deployment)](https://github.com/JamesClonk/k8s-infrastructure/actions/workflows/production.yml)
[![Platform](https://img.shields.io/badge/Platform-Kubernetes-blue)](https://kubernetes.io/)

Create your own personal Kubernetes infrastructure, the quick and easy way

## Quick start ⏩

```bash
## get this repository here
git clone https://github.com/JamesClonk/k8s-infrastructure
cd k8s-infrastructure

# adjust main configuration file:
vi configuration.yml

# adjust secrets file:
sops secrets.sops

# provision Kubernetes on Hetzner Cloud with CSI driver for persistent volumes
# and install these basic tools and software:
# ingress-nginx, cert-manager, dashboard, prometheus, loki, grafana, postgres
./deploy.sh

# configure DNS provider/entries, with loadbalancer-, floating- or server-ip:
# A       $INGRESS_DOMAIN     $IP 
# CNAME   *.$INGRESS_DOMAIN   $INGRESS_DOMAIN
```

## What is this? ❓️

This is a collection of scripts for a fully automated deployment of Kubernetes onto a [Hetzner Cloud](https://www.hetzner.com/cloud) virtual machine. It will use the Hetzner Cloud CLI to create a single VM, deploy [K3s](https://k3s.io) onto it, target the newly installed Kubernetes and deploy various additional components. The whole deployment process is entirely automated and idempotent, and can also run automatically via the included `.github/workflows`.

## Installation ❗️

Installation? There's nothing to install here. Just run the steps as mentioned above in "**Quick start**" and off you go, your very own personal Kubernetes cluster will be deployed on Hetzner Cloud. 🥳

## Configuration 🛠️

The provided default configuration inside `configuration.yml` is aimed at provisioning and using a type *CPX41* or higher Hetzner Cloud virtual machine, with at least 8 CPUs and16GB of memory.
You will have to modify `configuration.yml` and `sops secrets.sops` before you can provision your own Kubernetes cluster on Hetzner Cloud.

For example a *CX31* costs ~10€ per month and is billed hourly, which makes it a very cheap and super convenient option for testing purposes.
If you want to use a lower spec machine then you should also adjust resource values for some of the included components, mainly to reduce their memory footprint.
To do so simply go through each subdirectory and check their respective `values.yml`, if it contains a `__.resources.__` section you can adjust the values there.

#### postgres 🐘

Adjust `postgres.resources.memory_in_mb` to `256` for a minimal database sizing. You can disable the periodic backups by setting `pgbackup.enabled` to `false`, as each backup job can consume up to 1GB of memory while it is running. You can also configure the backup jobs maximum memory consumption via `pgbackup.resources.memory_in_mb`, though decreasing this value too much will cause the backup to fail and crash if it runs out of memory while creating a database dump.

#### prometheus 🔥

Adjust `prometheus.resources.requests|limits` to lower values to reduce maximum memory usage. Be careful not to set the limits too low, *prometheus-server* can crash easily due to running out-of-memory while running some heavy metrics queries against it.

## Architecture 🏛️

![Kubernetes](docs/architecture.png)

### Components 🔋

| Name | Description | URL |
|-|-|-|
| [K3s](https://k3s.io) | An easy to install, lightweight, fully compliant Kubernetes distribution packaged as a single binary | https://github.com/rancher/k3s |
| [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx) | An Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer | https://github.com/kubernetes/ingress-nginx |
| [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) | A proxy that provides authentication with Google, Azure, OpenID Connect and many more identity providers | https://github.com/oauth2-proxy/oauth2-proxy |
| [cert-manager](https://cert-manager.io) | Automatic certificate management on top of Kubernetes, using [Let's Encrypt](https://letsencrypt.org) | https://github.com/jetstack/cert-manager |
| [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard) | General-purpose web UI for Kubernetes clusters | https://github.com/kubernetes/dashboard |
| [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) | Add-on agent to generate and expose cluster-level metrics | https://github.com/kubernetes/kube-state-metrics |
| [Prometheus](https://prometheus.io) | Monitoring & alerting system, and time series database for metrics | https://github.com/prometheus |
| [Loki](https://grafana.com/oss/loki) | A horizontally-scalable, highly-available, multi-tenant log aggregation system | https://github.com/grafana/loki |
| [Grafana](https://grafana.com/grafana) | Monitoring and metric analytics & dashboards for Prometheus and Loki | https://github.com/grafana/grafana |
| [PostgreSQL](https://www.postgresql.org) | The world's most advanced open source relational database | https://www.postgresql.org/docs |

### Tools 🔧

| Name | Description | URL |
|-|-|-|
| [Hetzner Cloud](https://www.hetzner.com/cloud) | Command-line interface for interacting with Hetzner Cloud | https://github.com/hetznercloud/cli |
| [Mozilla SOPS](https://github.com/mozilla/sops) | Encrypt files with AWS KMS, GCP KMS, Azure Key Vault, age, and PGP | https://github.com/mozilla/sops |
| [kapp](https://get-kapp.io) | Deploy and view groups of Kubernetes resources as applications | [Carvel](https://carvel.dev) (formerly https://k14s.io) |
| [ytt](https://get-ytt.io) | Template and overlay Kubernetes configuration via YAML structures | [Carvel](https://carvel.dev) (formerly https://k14s.io) |
| [vendir](https://github.com/vmware-tanzu/carvel-vendir) | Declaratively state what files should be in a directory | [Carvel](https://carvel.dev) (formerly https://k14s.io) |
| [kbld](https://get-kbld.io) | Seamlessly incorporates image building, pushing, and resolution into deployment workflows | [Carvel](https://carvel.dev) (formerly https://k14s.io) |
| [kapp-controller](https://github.com/vmware-tanzu/carvel-kapp-controller) | Kubernetes controller for Kapp, provides App CRDs | [Carvel](https://carvel.dev) (formerly https://k14s.io) |
| [k9s](https://k9scli.io) | Terminal UI to interact with your Kubernetes clusters | https://github.com/derailed/k9s |

### Thoughts & considerations 🤔

#### Why not using operators? 🤷

Well, this is meant to be used for a *single-user* Kubernetes cluster, whether with only a one or multiple nodes, self-deployed or managed.  While operators are certainly cool pieces of software they don't really make much sense for a single-user scenario, hence I saw no reason to use the prometheus, grafana and postgres operators for those parts of this Kubernetes-infrastructure-as-code project.

#### ~Why using simple basic-auth for all ingresses? 🔐~

~I was considering and experimenting with using [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) and [authelia](https://github.com/authelia/authelia), but ultimately made the same decision as with regards to using operators. It simply doesn't make much sense for a single-user Kubernetes cluster, the engineering and operational overhead was not worth it. All I needed are static username+password credentials for securing my applications.~

~My recommendation would be to use one of these two if you have more requirements than me:~
- ~https://github.com/oauth2-proxy/oauth2-proxy (Simple oauth2 proxy to be used with GitHub for example)~
- ~https://github.com/authelia/authelia (Allows sophisticated auth configuration, 2FA, etc.)~

~Both can be configured easily to work well together with *ingress-nginx*.~

The above is not true anymore, because I am now actually using oauth2-proxy together with GitHub for all ingresses :joy:
