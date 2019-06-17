#
# Various utilities for development
#

.PHONY: launch
# deploy and launch grafana 
launch: deploy
	xdg-open $(grafana_host)/login 2>/dev/null >/dev/null &

.PHONY: init
# initialize a minikube cluster and deploy this project,
# all in one target.
init: 
	$(MAKE) -C $(infrastructure_repository)/minikube minikube_start
	terraform_auto_approve=-auto-approve $(MAKE) launch

# show the log for a specific container
.PHONY: container_log_%
container_log_%:
	kubectl logs $$(kubectl get pods --namespace kpi | grep $* | awk '{ print $$1 }') -c $* --namespace kpi | less

.PHONY: kpi-mysql-importer-log
kpi-mysql-importer-log: container_log_mysql-importer
.PHONY: kpi-athene2-content-provider-log
kpi-athene2-content-provider-log: container_log_athene2-content-provider
