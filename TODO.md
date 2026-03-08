# TODO

- migrate to envoy-gateway?
	- test first if you can make hostNetwork work, or some other way for port 80,443 with envoy-proxy???
	- if yes:
		- also implement Dex
		- remove oauth2-proxy
		- integrate with cert-manager
			- wildcard cert possible even?
		- change all ingresses to httproutes, add oidc securitypolicy:
			- dex
			- headlamp
			- monitoring:
				- grafana
				- prometheus

- migrate to vector
	- remove promtail
	- add vector

- switch all templating & secrets management to `plato`
	- get rid of ytt secrets loading, render secrets instead directly in ytt yamls
	- get rid of env var secrets load, render secrets instead directly in shellscripts
	- yaml-encrypted secrets.yaml, instead of binary-encrypted .sops file
	- template/rendered wireguard config as a file inside /hetzner-k3s folder
	- deployments migrated:
		- hetzner-k3s
		- kube-system
		- ingress-nginx | envoy-gateway
		- cert-manager
		- dex | oauth2-proxy (depends on envoy-gateway question)
		- headlamp
		- postgres
		- monitoring:
			- grafana
			- prometheus
			- loki
			- vector

- get rid of prometheus-msteams completely
	- migrate to prometheus-discord ???

- update deployments to latest version
	- update vendir.yml, sync, and verify if still rendering and deploying fine:
		- ingress-nginx | envoy-gateway
		- cert-manager
		- dex | oauth2-proxy (depends on envoy-gateway question)
		- headlamp
		- postgres
		- monitoring:
			- grafana
			- prometheus
			- loki
			- vector
			- prometheus-discord ???

- switch cx32 to cpx32 once ready for prod deployment

