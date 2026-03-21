# TODO

- switch all templating & secrets management to `plato`
	- dont plato-render secrets into helm chart values.yamls, since helm chart output gets stored in git
	- all helm chart dependencies need to be accounted for and mirrored/vendired too! No internet!
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

- run a new pgbackup job after db cleanup, to make sure you got a backup after size reduction (in both, backman and pgbackup sidecar cronjob)

- switch cx32 to cpx32 once ready for prod deployment
