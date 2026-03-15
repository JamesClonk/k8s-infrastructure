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

- update all cert-manager annotations to point to "letsencrypt-prod" instead of "letsencrypt-staging"

- go through all remaining "# TODO:" comments

- implement OIDC via GitHub in Dex, add connector and test it

- cleanup current prod postgres database before merging this branch, the current backups are overly large, we dont need more than lets say 2 years of data in irvisualizer db
- run a new pgbackup job after db cleanup, to make sure you got a backup after size reduction (in both, backman and pgbackup sidecar cronjob)

- switch cx32 to cpx32 once ready for prod deployment
