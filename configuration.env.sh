########################################################################################################################
####### kubectl config file ############################################################################################
########################################################################################################################
export KUBECONFIG="$HOME/.kube/hetzner-k3s"
########################################################################################################################


########################################################################################################################
####### hetzner cloud - k3s ############################################################################################
########################################################################################################################
export HCLOUD_TOKEN="${HCLOUD_TOKEN}" # https://docs.hetzner.cloud/#getting-started

export HETZNER_SSH_KEY_NAME="kubernetes"
export HETZNER_PUBLIC_SSH_KEY="${HETZNER_PUBLIC_SSH_KEY}" # your _public_ ssh-key

export HETZNER_PRIVATE_NETWORK_NAME="k8s-private"
export HETZNER_PRIVATE_NETWORK_RANGE="10.8.0.0/16"
export HETZNER_PRIVATE_NETWORK_SUBNET="10.8.0.0/24"
export HETZNER_PRIVATE_NETWORK_ZONE="eu-central"

export HETZNER_NODE_NAME="kubernetes-server"
export HETZNER_NODE_TYPE="cx11" # https://www.hetzner.com/cloud#pricing
export HETZNER_NODE_IMAGE="ubuntu-20.04"
export HETZNER_NODE_LOCATION="nbg1" # https://docs.hetzner.com/general/others/data-centers-and-connection

export HETZNER_FLOATING_IP_ENABLED="true" # set to 'true' if you want a floating-ip assigned to your server
export HETZNER_FLOATING_IP_NAME="kubernetes-vip"

export HETZNER_LOADBALANCER_ENABLED="false" # set to 'true' if you want a Hetzner load-balancer in front of your server
export HETZNER_LOADBALANCER_NAME="kubernetes-lb"
export HETZNER_LOADBALANCER_TYPE="lb11" # https://www.hetzner.com/cloud/load-balancer#pricing

export HETZNER_K3S_VERSION="v1.19.3+k3s2" # https://github.com/rancher/k3s/releases
########################################################################################################################


########################################################################################################################
####### ingress-nginx ##################################################################################################
########################################################################################################################
export INGRESS_DOMAIN="${INGRESS_DOMAIN}" # for example "mydomain.org"
########################################################################################################################


########################################################################################################################
####### cert-manager ###################################################################################################
########################################################################################################################
export LETS_ENCRYPT_EMAIL_ADDRESS="${LETS_ENCRYPT_EMAIL_ADDRESS}" # for example "admin@mydomain.org"
########################################################################################################################


########################################################################################################################
####### kubernetes-dashboard ###########################################################################################
########################################################################################################################
export DASHBOARD_BASIC_AUTH_USERNAME="${DASHBOARD_BASIC_AUTH_USERNAME}" # for example "my-username"
export DASHBOARD_BASIC_AUTH_PASSWORD="${DASHBOARD_BASIC_AUTH_PASSWORD}" # for example "my-super-secret-password"
########################################################################################################################

