# TODO

- switch all templating & secrets management to `plato`
	- get rid of ytt secrets loading, render secrets instead directly in ytt yamls
	- get rid of env var secrets load, render secrets instead directly in shellscripts
	- yaml-encrypted secrets.yaml, instead of binary-encrypted .sops file
	- template/rendered wireguard config as a file inside /hetzner-k3s folder
	- deployments migrated:
		- hetzner-k3s
		- kube-system
		- envoy-gateway
		- ~cert-manager~
		- dex
		- headlamp
		- postgres
		- monitoring:
			- grafana
			- prometheus
			- loki
			- vector

- go through all remaining "# TODO:" comments

- implement OIDC via GitHub in Dex, add connector and test it
