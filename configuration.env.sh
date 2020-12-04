########################################################################################################################
####### kubectl config file ############################################################################################
########################################################################################################################
export KUBECONFIG="$HOME/.kube/hetzner-k3s"
########################################################################################################################


########################################################################################################################
####### hetzner cloud - k3s ############################################################################################
########################################################################################################################
export HCLOUD_TOKEN="${HCLOUD_TOKEN:=invalid}" # https://docs.hetzner.cloud/#getting-started

export HETZNER_SSH_PORT="22333"
export HETZNER_SSH_KEY_NAME="kubernetes"
export HETZNER_PUBLIC_SSH_KEY="${HETZNER_PUBLIC_SSH_KEY:=invalid}" # your _public_ ssh-key

export HETZNER_PRIVATE_NETWORK_NAME="k8s-private"
export HETZNER_PRIVATE_NETWORK_RANGE="10.8.0.0/16"
export HETZNER_PRIVATE_NETWORK_SUBNET="10.8.0.0/24"
export HETZNER_PRIVATE_NETWORK_ZONE="eu-central"

export HETZNER_NODE_NAME="kubernetes-server"
export HETZNER_NODE_TYPE="cpx41" # https://www.hetzner.com/cloud#pricing
export HETZNER_NODE_IMAGE="ubuntu-20.04"
export HETZNER_NODE_LOCATION="nbg1" # https://docs.hetzner.com/general/others/data-centers-and-connection

export HETZNER_FLOATING_IP_ENABLED="true" # set to 'true' if you want a floating-ip assigned to your server
export HETZNER_FLOATING_IP_NAME="kubernetes-vip"

export HETZNER_LOADBALANCER_ENABLED="false" # set to 'true' if you want a Hetzner load-balancer in front of your server
export HETZNER_LOADBALANCER_NAME="kubernetes-lb"
export HETZNER_LOADBALANCER_TYPE="lb11" # https://www.hetzner.com/cloud/load-balancer#pricing

export HETZNER_K3S_VERSION="v1.19.4+k3s1" # https://github.com/rancher/k3s/releases
########################################################################################################################


########################################################################################################################
####### ingress-nginx ##################################################################################################
########################################################################################################################
export INGRESS_DOMAIN="${INGRESS_DOMAIN:=example.org}" # for example "mydomain.org"
export INGRESS_BASIC_AUTH_USERNAME="${INGRESS_BASIC_AUTH_USERNAME:=username}" # for example "my-username"
export INGRESS_BASIC_AUTH_PASSWORD="${INGRESS_BASIC_AUTH_PASSWORD:=password}" # for example "my-super-secret-password"
########################################################################################################################


########################################################################################################################
####### cert-manager ###################################################################################################
########################################################################################################################
export LETS_ENCRYPT_EMAIL_ADDRESS="${LETS_ENCRYPT_EMAIL_ADDRESS:=nobody@nobody}" # for example "admin@mydomain.org"
export LETS_ENCRYPT_PROD_KEY="${LETS_ENCRYPT_PROD_KEY:=none}" # optional, base64 encoded tls key of existing account
export LETS_ENCRYPT_STAGING_KEY="${LETS_ENCRYPT_STAGING_KEY:=none}" # optional, base64 encoded tls key of existing account
########################################################################################################################


########################################################################################################################
####### prometheus #####################################################################################################
########################################################################################################################
export PROMETHEUS_ALERTMANAGER_EMAIL_ENABLED="${PROMETHEUS_ALERTMANAGER_EMAIL_ENABLED:=false}" # false or true
export PROMETHEUS_ALERTMANAGER_EMAIL_HOST="${PROMETHEUS_ALERTMANAGER_EMAIL_HOST:=smtp.gmail.com:587}"
export PROMETHEUS_ALERTMANAGER_EMAIL_PASSWORD="${PROMETHEUS_ALERTMANAGER_EMAIL_PASSWORD:=password}"
export PROMETHEUS_ALERTMANAGER_EMAIL_FROM="${PROMETHEUS_ALERTMANAGER_EMAIL_FROM:=nobody@nobody}"
export PROMETHEUS_ALERTMANAGER_EMAIL_TO="${PROMETHEUS_ALERTMANAGER_EMAIL_TO:=nobody@nobody}"
export PROMETHEUS_ALERTMANAGER_TEAMS_WEBHOOK_ENABLED="${PROMETHEUS_ALERTMANAGER_TEAMS_WEBHOOK_ENABLED:=true}" # false or true
export PROMETHEUS_ALERTMANAGER_TEAMS_WEBHOOK_URL="${PROMETHEUS_ALERTMANAGER_TEAMS_WEBHOOK_URL:=http://example/deadbeef}" # https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook
########################################################################################################################


########################################################################################################################
####### grafana ########################################################################################################
########################################################################################################################
export GRAFANA_USERNAME="${GRAFANA_USERNAME:=${INGRESS_BASIC_AUTH_USERNAME}}" # for example "my-username"
export GRAFANA_PASSWORD="${GRAFANA_PASSWORD:=${INGRESS_BASIC_AUTH_PASSWORD}}" # for example "my-super-secret-password"
########################################################################################################################
