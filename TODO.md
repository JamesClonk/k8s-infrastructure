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
		- cert-manager
		- dex
		- headlamp
		- postgres
		- monitoring:
			- grafana
			- prometheus
			- loki
			- vector

- update deployments to latest version
	- update vendir.yml, sync, and verify if still rendering and deploying fine:
		- ~envoy-gateway~
		- ~cert-manager~
		- ~dex~
		- ~headlamp~
		- postgres
		- ~monitoring:~
			- ~grafana~
			- ~prometheus~
			- ~loki~
			- ~vector~

- update all cert-manager annotations to point to "letsencrypt-prod" instead of "letsencrypt-staging"

- go through all remaining "# TODO:" comments

- implement OIDC via GitHub in Dex, add connector and test it

- switch cx32 to cpx32 once ready for prod deployment

